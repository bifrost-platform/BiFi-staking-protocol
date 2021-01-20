module.exports = {
  networks: {},
  mocha: {},
  compilers: {
    solc: {
       version: "0.6.12",
       optimizer: {
         enabled: false,
         runs: 200
       },
    }
  }
};
