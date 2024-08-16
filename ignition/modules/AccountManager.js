const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("Chainfolio", (m) => {
    const zrSign = m.getParameter("zrSign");

    const accountManager = m.contract("AccountManager", [zrSign]);

    return { accountManager };
});
