// Copyright 2019-2023 ChainSafe Systems
// SPDX-License-Identifier: Apache-2.0, MIT

use std::path::{Path, PathBuf};

use anyhow::bail;
use chrono::NaiveDateTime;
use clap::Parser;
use env_logger::Env;
use log::{debug, info};
use rayon::prelude::*;

type ChainEpoch = u64;
const EPOCH_DURATION_SECONDS: u64 = 30;

#[derive(Parser, Debug)]
struct Args {
    #[arg(long, default_value = "calibnet")]
    /// Network used. This is used to properly name the generated snapshots.
    network: String,
    #[arg(long, default_value = "30000")]
    /// Number of epochs between each lite snapshot
    lite_snapshot_every_n_epochs: u64,
    #[arg(long, default_value = "900")]
    /// Number of epochs to include in each lite snapshot
    lite_snapshot_depth: u64,
    #[arg(long, default_value = "10")]
    /// Number of diff snapshots to generate between lite snapshots
    diff_snapshots_between_lite: u64,
    #[arg(long)]
    /// Disable lite snapshots generation
    no_lite_snapshots: bool,
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
    (0..=epochs)
        .step_by(args.lite_snapshot_every_n_epochs as usize)
        .par_bridge()
        .for_each(|epoch_boundary| {
            if !args.no_lite_snapshots {
                generate_lite_snapshot(
                    epoch_boundary,
                    args.lite_snapshot_depth,
                    &args.snapshot_file,
                )
                .expect("failed to generate lite snapshot");
            }

            if epoch_boundary == 0 {
                return;
            }

            // generate diff snapshots between the lite snapshots
            for epoch in (epoch_boundary - args.lite_snapshot_every_n_epochs..=epoch_boundary)
                .step_by(diff_snapshot_depth as usize)
                .skip(1)
            {
                let diff = epoch - diff_snapshot_depth;
                let diff_depth = diff - (epoch_boundary - args.lite_snapshot_every_n_epochs)
                    + args.lite_snapshot_depth;
                generate_diff_snapshot(
                    diff,
                    epoch,
                    diff_snapshot_depth,
                    diff_depth,
                    &args.snapshot_file,
                    &args.network,
                )
                .expect("failed to generate diff snapshot");
            }
        });

    Ok(())
}

fn generate_lite_snapshot(
    epoch: u64,
    lite_snapshot_depth: u64,
    snapshot_file: &Path,
) -> anyhow::Result<()> {
    debug!("Generating lite snapshot for epoch {epoch}");
    std::process::Command::new("forest-cli")
        .args([
            "archive",
            "export",
            "--epoch",
            epoch.to_string().as_str(),
            "--depth",
            lite_snapshot_depth.to_string().as_str(),
            snapshot_file
                .to_str()
                .ok_or_else(|| anyhow::anyhow!("invalid snapshot file"))?,
        ])
        .output()?;
    info!("Generated lite snapshot for epoch {epoch}");
    Ok(())
}

fn generate_diff_snapshot(
    diff: u64,
    epoch: u64,
    diff_snapshot_depth: u64,
    diff_depth: u64,
    snapshot_file: &Path,
    network: &str,
) -> anyhow::Result<()> {
    debug!("Generating diff snapshot for epochs: [{diff}, {epoch}]");
    let diff_snapshot_name = format!(
        "forest_diff_{}_{}_height_{}+{}.forest.car.zst",
        network,
        epoch_to_date(diff + diff_snapshot_depth),
        diff,
        diff_snapshot_depth
    );

    if Path::new(&diff_snapshot_name).exists() {
        info!("Diff snapshot for epochs: [{diff}, {epoch}] already exists",);
        return Ok(());
    }

    std::process::Command::new("forest-cli")
        .args([
            "archive",
            "export",
            "--epoch",
            epoch.to_string().as_str(),
            "--depth",
            diff_snapshot_depth.to_string().as_str(),
            "--diff",
            diff.to_string().as_str(),
            "--diff-depth",
            diff_depth.to_string().as_str(),
            "--output-path",
            diff_snapshot_name.as_str(),
            snapshot_file
                .to_str()
                .ok_or_else(|| anyhow::anyhow!("invalid snapshot file"))?,
        ])
        .output()?;

    info!("Generated diff snapshot for epochs: [{diff}, {epoch}]");
    Ok(())
}

fn epoch_to_date(epoch: ChainEpoch) -> String {
    let genesis_timestamp = 1667326380;

    NaiveDateTime::from_timestamp_opt(
        (genesis_timestamp + epoch * EPOCH_DURATION_SECONDS) as i64,
        0,
    )
    .unwrap_or_default()
    .format("%Y-%m-%d")
    .to_string()
}
