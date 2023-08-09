// Copyright 2019-2023 ChainSafe Systems
// SPDX-License-Identifier: Apache-2.0, MIT

use std::path::PathBuf;

use anyhow::bail;
use clap::Parser;
use env_logger::Env;
use log::{debug, info};
use rayon::prelude::*;

#[derive(Parser, Debug)]
struct Args {
    #[arg(long, default_value = "calibnet")]
    /// Network used. This is used to properly name the generated snapshots.
    network: String,
    #[arg(long, default_value = "30000")]
    /// Number of epochs between each lite snapshot
    lite_snapshot_every_n_epochs: u64,
    #[arg(long, default_value = "2000")]
    /// Number of epochs to include in each lite snapshot
    lite_snapshot_depth: u64,
    #[arg(long, default_value = "10")]
    /// Number of diff snapshots to generate between lite snapshots
    diff_snapshots_between_lite: u64,
    /// Full snapshot file to generate lite and diff snapshots from
    snapshot_file: PathBuf,
}

fn main() -> anyhow::Result<()> {
    if which::which("forest-cli").is_err() {
        bail!("forest-cli is not installed");
    }

    env_logger::Builder::from_env(Env::default().default_filter_or("info")).init();

    let args = Args::parse();

    info!("Analyzing the provided snapshot file");
    let epochs = std::process::Command::new("forest-cli")
        .args([
            "archive",
            "info",
            args.snapshot_file.to_str().expect("invalid snapshot file"),
        ])
        .output()
        .map(|output| {
            let stdout = String::from_utf8(output.stdout).ok()?;
            debug!("{}", stdout);
            stdout.lines().find_map(|line| {
                let (k, v) = line.split_once(':')?;

                if k == "Epoch" {
                    Some(v.trim().parse::<u64>().ok()?)
                } else {
                    None
                }
            })
        })?
        .ok_or_else(|| anyhow::anyhow!("Failed to get epochs from the info command"))?;

    info!(
        "This command will start generating snapshots from epoch 0 to epoch {epochs} now. There will be {} lite snapshots with {} diff snapshots in between them.",
        epochs / args.lite_snapshot_every_n_epochs,
        args.diff_snapshots_between_lite
    );

    // limit the number of threads to half the number of cores to avoid overloading the system and
    // OOMing
    rayon::ThreadPoolBuilder::new()
        .num_threads(std::thread::available_parallelism()?.get() / 2)
        .build_global()
        .expect("failed to build rayon thread pool");

    let diff_snapshot_depth = args.lite_snapshot_every_n_epochs / args.diff_snapshots_between_lite;
    (0..epochs)
        .step_by(args.lite_snapshot_every_n_epochs as usize)
        .par_bridge()
        .for_each(|epoch_boundary| {
            debug!("Generating lite snapshot for epoch {}", epoch_boundary);
            std::process::Command::new("forest-cli")
                .args([
                    "archive",
                    "export",
                    "--epoch",
                    epoch_boundary.to_string().as_str(),
                    "--depth",
                    args.lite_snapshot_depth.to_string().as_str(),
                    args.snapshot_file.to_str().expect("invalid snapshot file"),
                ])
                .output()
                .expect("failed to generate lite snapshot");
            info!("Generated lite snapshot for epoch {}", epoch_boundary);

            if epoch_boundary == 0 {
                return;
            }

            // generate diff snapshots between the lite snapshots
            for epoch in (epoch_boundary - args.lite_snapshot_every_n_epochs..epoch_boundary)
                .step_by(diff_snapshot_depth as usize)
                .skip(1)
            {
                let start_epoch = epoch - diff_snapshot_depth;
                debug!("Generating diff snapshot for epochs: [{start_epoch}, {epoch}]");
                let diff_snapshot_name = format!(
                    "forest_diff_{}_height_{}+{}.forest.car.zst",
                    args.network, start_epoch, diff_snapshot_depth
                );

                std::process::Command::new("forest-cli")
                    .args([
                        "archive",
                        "export",
                        "--epoch",
                        epoch.to_string().as_str(),
                        "--depth",
                        diff_snapshot_depth.to_string().as_str(),
                        "--diff",
                        start_epoch.to_string().as_str(),
                        "--output-path",
                        diff_snapshot_name.as_str(),
                        args.snapshot_file.to_str().expect("invalid snapshot file"),
                    ])
                    .output()
                    .expect("failed to generate diff snapshot");

                info!("Generated diff snapshot for epochs: [{start_epoch}, {epoch}]");
            }
        });

    Ok(())
}
