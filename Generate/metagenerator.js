for (let i = 1; i <= 500; i++) {
    let j = getNumber(i);
    obj = {
        "name": "JPGO Club VIP Pass #" + j,
        "description": "在这里，我们交流与分享：日本居住权最新申请方法，在日财税筹划，商业合作或投资机会，日本企业招聘信息，各大名校招生信息，生活，旅游，居住常用日语等等一切与在日生活相关的前沿资讯。",
        "image": "https://gateway.pinata.cloud/ipfs/QmdrHGdpcWeF8ZbXXnz8iLkBtwRqHXREZowDoXhE2bwZUz"
    };
    var json = JSON.stringify(obj);
    var fs = require('fs');
    fs.writeFile('JPGO Club VIP Pass #' + j + '.json', json, (err) => {
        if (err) throw err;
        console.log('Data written to the file');
    });
    console.log(json);
}

function getNumber(num) {
    num = num.toString();
    if (num <= 9) {
        num = "00" + num;
        return num;
    }
    if (num >= 9 && num <= 99) {
        num = "0" + num;
        return num;
    } else {
        return num;
    }
}