# Remix Team IDE

That version of [Remix IDE](https://github.com/ethereum/remix) are based on the original browser-based compiler, but includes several modifications for faster buld on your server (*from the box*)  and better multiuser experiens for smart contracts development.

**RemixTeamIDE:**
1. Cutted welcome alerts
2. You can preselect compiler version
3. You can preselect test network address (ganache, geth, etc...)
4. You can **connect and share server local contracts**

***

### INSTALLATION:

Download [RemixTeamIDE](https://github.com/udartsev/RemixTeamIDE.git) repo:

```
git clone https://github.com/udartsev/RemixTeamIDE.git
```

Go to the [RemixTeamIDE](https://github.com/udartsev/RemixTeamIDE.git)  folder:
```
cd RemixTeamIDE
```

Install Node modules:
```
npm install 
```

Fix Node issues if needs:
```
npm audit fix
```

Compile Node script:
```
npm run build
```

Edit [RemixTeamIDE](https://github.com/udartsev/RemixTeamIDE.git) setting file:
```
vim settings.js
```

Edit **package.json**, **change** localhost address to your server host ip:
```
"scripts": { 
  ...
    "remixd": "./remixd/bin/remixd -s ./contracts --remix-ide http://127.0.0.1:8080",
  ...
}
```
**to:**
```
"scripts": { 
  ...
    "remixd": "./remixd/bin/remixd -s ./contracts --remix-ide http://[SERVER_IP]:8080",
  ...
}
```

***

### SETTINGS.js example
```
export let SERVER_IP = '127.0.0.1';
export let SERVER_PORT	= '8080';
export let TESTNET_IP = '127.0.0.1';
export let TESTNET_PORT = '8545';
export let COMPILER_VER = 'soljson-v0.5.7+commit.6da8b019';
export let TEAMNAME = 'SUPERTEAM';
```
**Where:**
1. **SERVER_IP** = use `127.0.0.1` for localhost
2. **SERVER PORT** = `8080` standart *node serve* port 
3. **TESTNET_IP** = is your ganache, myst or geth Ethereum network. Use `8545` for a standart ganache-cli port
4. **TESTNET_PORT** = is your ganache, myst or geth Ethereum network
5. **COMPILER_VER** = solc version like: `soljson-v0.5.7+commit.6da8b019`
6. **TEAMNAME** = just your development team name

***

### DEVELOPING:

Copy your Solidity contracts files to ./contracts folder: 
```
cp -fR ./[your contracts] RemixTeamIDE/contracts
``` 

Run from **sudo**: 
```
sudo npm start
``` 

Open in your browser: 
```
http://[SERVER]:8080
``` 

Now you and your team can open **.sol** files locale on the **./contracts** folder on your server. 

The browser will automatically refresh when files are saved.

***
To see details about how to use Remix for developing and/or debugging Solidity contracts, please see [official remix documentation page](https://remix.readthedocs.io).
***

