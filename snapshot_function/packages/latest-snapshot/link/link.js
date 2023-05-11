const fetch = require('node-fetch');
const { XMLParser, XMLBuilder, XMLValidator } = require("fast-xml-parser");

const region = 'fra1'
const bucket = 'forest-snapshots'

const base_url = 'https://' + region + '.digitaloceanspaces.com/' + bucket;

// "calibnet/forest_snapshot_calibnet_2022-11-30_height_81393.car"

async function main(args) {
    // default to compressed snapshots unless we're told otherwise
    let compressed = !(args.compressed === 'false' || args.compressed === 'no' || args.compressed === '0');

    // default to the calibnet network unless we're told otherwise
    let network = args.network || 'calibnet';

    const response = await fetch(base_url);
    const body = await response.text();

    const parser = new XMLParser();
    let jObj = parser.parse(body);

    const re = /([^_]+?)_snapshot_([^_]+?)_(\d{4}-\d{2}-\d{2})_height_(\d+).car(.zst)?$/;

    var snapshots = [];

    for (var i = 0; i < jObj.ListBucketResult.Contents.length; i++) {
        const key = jObj.ListBucketResult.Contents[i].Key;
        const myArray = key.match(re);
        if (myArray) {
            let snapshot = { "key": key, "provider": myArray[1], "network": myArray[2], "date": myArray[3], "epoch": parseInt(myArray[4]), "compressed": myArray[5] === '.zst' };
            if (snapshot.network === network && snapshot.compressed === compressed) {
                snapshots.push(snapshot);
            }
        }
    }
    snapshots.sort(function (a, b) { return b.epoch - a.epoch; });
    if( snapshots.length == 0) {
        return { "statusCode": 404, "body": "No match snapshot found"};
    } else {
        return { "statusCode": 302, "body": "redirecting", headers: { "location": base_url + '/' + snapshots[0].key } };
    }
}
