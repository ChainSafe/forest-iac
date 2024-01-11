// eslint-disable-next-line @typescript-eslint/no-var-requires -- "approved" methods of resolving this lint do not work in the NR context.
var assert = require("assert");

function check_snapshot(url, genesisTime) {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars -- that's how the callback works in this context.
  var callback = function (_err, response, _body) {
    assert.equal(response.statusCode, 200, "Expected a 200 OK response");

    var snapshotName = response.url.split("/").pop();
    var height = snapshotName.match(/height_(\d+)/)[1];

    var currentTime = Math.floor(Date.now() / 1000);
    var snapshotTime = height * 30 + genesisTime;
    var snapshotAgeInMinutes = (currentTime - snapshotTime) / 60;

    assert(
      snapshotAgeInMinutes < 360,
      "Expected snapshot to be less than 360 minutes old"
    );
  };

  // This variable is provided by New Relic.
  // eslint-disable-next-line no-undef
  $http.head(url, callback);
}

check_snapshot(
  "https://forest-archive.chainsafe.dev/latest/calibnet/",
  1667326380
);
check_snapshot(
  "https://forest-archive.chainsafe.dev/latest/mainnet/",
  1598306400
);
