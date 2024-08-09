const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("Chainfolio", (m) => {
    const zrSign = m.getParameter("zrSign");
    const executor = m.getParameter("executor");

    const accountManager = m.contract("AccountManager", [executor, zrSign]);

    return { accountManager };
});
