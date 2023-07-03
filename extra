'use strict';

const fs = require('fs');
const qlogFile = process.argv[2];
const qlog = JSON.parse(fs.readFileSync(qlogFile));
let num = 0;
let sum = 0;
for (const event of qlog.traces[0].events) {
	if (event.data && event.data.latest_rtt) {
		num++;
		sum += event.data.latest_rtt;
	}
}
console.log('average rtt = ', sum/num);
