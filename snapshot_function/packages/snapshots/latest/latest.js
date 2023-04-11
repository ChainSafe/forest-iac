const fetch = require('node-fetch');
const { XMLParser, XMLBuilder, XMLValidator } = require("fast-xml-parser");

const region = 'fra1'
const bucket = 'forest-snapshots'

const base_url = 'https://' + region + '.digitaloceanspaces.com/' + bucket;

// "calibnet/forest_snapshot_calibnet_2022-11-30_height_81393.car"

async function main(args) {

    const response = await fetch(base_url);
    const body = await response.text();

    const parser = new XMLParser();
    let jObj = parser.parse(body);

    const re = /([^_]+?)_snapshot_([^_]+?)_(\d{4}-\d{2}-\d{2})_height_(\d+).car?$/;

    var snapshots = [];

    for (var i = 0; i < jObj.ListBucketResult.Contents.length; i++) {
        // console.log("Obj: ", jObj.ListBucketResult.Contents[i]);
        const key = jObj.ListBucketResult.Contents[i].Key;
        const myArray = key.match(re);
        if (myArray) {
            let snapshot = { "key": key, "provider": myArray[1], "network": myArray[2], "date": myArray[3], "epoch": parseInt(myArray[4]) };
            if (snapshot.network === 'calibnet') {
                snapshots.push(snapshot);
            }
        }
    }
    snapshots.sort(function (a, b) { return b.epoch - a.epoch; });
    return { "statusCode": 302, "body": "redirecting", headers: { "location": base_url + '/' + snapshots[0].key } };

}
