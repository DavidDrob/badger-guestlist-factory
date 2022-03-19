pragma solidity 0.6.12;

import "@openzeppelinupgradeabel/contracts/token/ERC20/IERC20Upgradeable.sol";

interface IVault {
    function token() external view returns (IERC20Upgradeable);
}
