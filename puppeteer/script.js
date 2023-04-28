const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({
            executablePath: "/usr/bin/google-chrome",
            args:
            [   
                '--no-sandbox', 
                '--origin-to-force-quic-on=server4:4000/',
                // '--ignore-certificate-errors-spki-list=MXch2+++ogkqdwXJ2vg1wjfWofvrhffYBonp8nHy5Z0=',
            ],
        });
  const page = await browser.newPage();
  await page.goto('https://server4.com/');
  await browser.close();
  console.log('done');
})();