const fs = require('fs');
const { SerialPort } = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');
const notifier = require('node-notifier');
const HTML_FILE = __dirname + "/index.html";

const RAW_HTML = `
<!DOCTYPE html>
<html lang="pt-br">
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
            background-color: #ffff;
            color: #000;
        }
        header {
            display: flex;
            flex-direction: row;
            justify-content: space-between;
            align-items: right;
        }

        p, h1, h2, h3, a, ul {
            margin: 0;
            padding: 0;
            text-decoration: none;
            color: #000;
        }
        
        h1 {
            margin-bottom: 20px;
        }

        h2 {
            margin-bottom: 40px;
        }
        h3 {
            text-transform: capitalize;
            margin-bottom: 20px;
        }
        .limpar-logs {
            cursor: pointer;
            outline: 0;
            color: #fff;
            background-color: #fd0d0d;
            border-color: #fd0d0d;
            display: inline-block;
            font-weight: 400;
            line-height: 1.5;
            text-align: center;
            border: 1px solid transparent;
            padding: 6px 12px;
            font-size: 16px;
            border-radius: .25rem;
            transition: color .15s ease-in-out,background-color .15s ease-in-out,border-color .15s ease-in-out,box-shadow .15s ease-in-out;   
        }
        .log-access {
            background-color: hsla(102, 100%, 50%, 0.425);
        }
        .log-blocked {
            background-color: hsla(0, 100%, 50%, 0.425);
        }
    </style>
</head>

<body class="w3-dark-mode">
    <h1>Logs</h1>
    <header> 
        <h3>Confira as atividades recentes no seu portão:</h3>
    </header>
    <h4>
    <!-- REPLACE DIV -->
    </h4>

</body>
</html>
`

async function findPort() {
    try {
        const ports = await SerialPort.list();
        return ports.find(p => p.vendorId && p.vendorId.toLowerCase() === '2341');
    }
    catch (err) {
        console.error("Erro ao listar portas seriais: ", err.message);
        return null;
    }
}

async function listen() {
    const gotPort = await findPort();
    if (!gotPort) {
        console.error("Não foram encontradas portas com Arduino.");
        console.log("Insira o Arduino e tente novamente.");
        return;
    }
    try {
        const port = new SerialPort({path: gotPort.path, baudRate: 9600});

        port.on('error', (err) => {
            console.error("Erro na porta serial:", err.message);
        });

        console.log("Arduino identificado na porta ", gotPort.path);
        const parser = port.pipe(new ReadlineParser({delimiter: '\r\n'}));
        parser.on('data', (line) => {
            line = line.trim();
            let status = 0 // 1 aberto 2 bloqueado 3 máximo de tentativas
            if (line == 'HIGH') {
                status = 1;
            }
            else if (line == 'LOW') {
                status = 2;
            }
            else if (line == 'MAX') {
                notifier.notify({
                    title: 'Máximo de tentativas incorretas atingido',
                    message: 'O portão foi bloqueado devido a muitas tentativas incorretas.',
                    sound: true,
                    wait: true
                });
                status = 3;
            }
            writeHtml(status);
        });
    }
    catch (err) {
        console.error("Erro ao abrir a porta serial: ", err.message);
        return;
    }
}

listen();
console.log("Execute LIMPAR_LOGS para limpar todos os registros");

function writeHtml(status) {
    if(status === 0) return;
    const d = new Date();
    const time = d.toTimeString();
    const timeWithoutGMT = time.split(" GMT")[0];
    const day = d.toDateString();

    let newDiv = "";

    switch(status) {
        case 1: newDiv = `<div class="log-access">${timeWithoutGMT}, ${day} - Portão aberto com sucesso</div>`; break;
        case 2: newDiv = `<div class="log-blocked">${timeWithoutGMT}, ${day} - Tentativa incorreta bloqueada</div>`; break;
        case 3: newDiv = `<div class="log-blocked">${timeWithoutGMT}, ${day} - Máximo de tentativas incorretas atingido</div>`; break;
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
