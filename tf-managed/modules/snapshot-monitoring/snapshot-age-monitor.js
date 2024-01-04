var assert = require('assert');

function check_snapshot(url, genesisTime) {
  var callback = function (err, response, body) {
    assert.equal(response.statusCode, 200, 'Expected a 200 OK response');

    var snapshotName = response.url.split('/').pop();
    var height = snapshotName.match(/height_(\d+)/)[1];

    var currentTime = Math.floor(Date.now() / 1000);
    var snapshotTime = height * 30 + genesisTime;
    var snapshotAgeInMinutes = (currentTime - snapshotTime) / 60;

    assert(snapshotAgeInMinutes < 360, 'Expected snapshot to be less than 360 minutes old');
  }

  $http.head(url, callback)
}

check_snapshot('https://forest-archive.chainsafe.dev/latest/calibnet/', 1667326380)
check_snapshot('https://forest-archive.chainsafe.dev/latest/mainnet/', 1598306400)
