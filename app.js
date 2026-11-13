const fs = require('fs');
const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');
const HTML_FILE = "./index.html";

const RAW_HTML = `
<!DOCTYPE html>
<html lang=pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Logs</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Noto+Serif:wght@400;700&display=swap');

        body {
            max-width: 1200px;
            margin: 20px auto;
            padding: 0 20px;
            font-family: 'Noto Serif', serif;
            max-width: 1200px;
        }
        p, h1, h2, h3, a, ul {
            margin: 0;
            padding: 0;
            text-decoration: none;
            color: #222;
        }

        h2 {
            margin-bottom: 40px;
        }
        h3 {
            text-transform: capitalize;
            margin-bottom: 8px;
        }
        .log-access {
            background-color: hsla(102, 100%, 50%, 0.425);
        }
        .log-blocked {
            background-color: hsla(0, 100%, 50%, 0.425);
        }
    </style>
</head>
<body>
    <h1>Logs</h1>
    <h3>Confira as atividades recentes no seu portão:</h3>
    <h4>
    <!-- REPLACE DIV -->
    </h4>
</body>
</html>
`

async function findPort() {
    const ports = await SerialPort.list();
    return ports.find(p => p.vendorId && p.vendorId.toLowerCase() === '2341');
}

async function listen() {
    const gotPort = await findPort();
    if (!gotPort) {
        console.error("Não foram encontradas portas com Arduino.");
        return;
    }
    const port = new SerialPort({path: gotPort.path, baudRate: 9600});
    console.log("Arduino identificado na porta ", gotPort.path);
    const parser = port.pipe(new ReadlineParser({delimiter: '\r\n'}));
    parser.on('data', (line) => {
        let status = 0 // 1 aberto 2 bloqueado
        if(line == 'HIGH') {
            status = 1;
        }
        else if (line == 'LOW') {
            status = 2;
        }
        writeHtml(status);
    });
}

listen();

function writeHtml(status) {
    const d = new Date();
    const day = d.toDateString();
    const time = d.toTimeString();
    const timeWithoutGMT = time.split(" GMT")[0];
    let newDiv = "";

    switch(status) {
        case 1: newDiv = `<div class="log-access">${timeWithoutGMT}, ${day} - Portão aberto com sucesso</div>`; break;
        case 2: newDiv = `<div class="log-blocked">${timeWithoutGMT}, ${day} - Tentativa incorreta bloqueada</div>`
    }

    if (!fs.existsSync(HTML_FILE)) {
        console.log("Arquivo HTML não existe.");
        console.log("Criando arquivo...");
        fs.writeFileSync(HTML_FILE, RAW_HTML);
    }

    const data = fs.readFileSync(HTML_FILE, { encoding: 'utf-8', flag: 'r' })
    .replace("<!-- REPLACE DIV -->",
    `<!-- REPLACE DIV -->
    ${newDiv}`
    );

    fs.writeFileSync(HTML_FILE, data);
}

