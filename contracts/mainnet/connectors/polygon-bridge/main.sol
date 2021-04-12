pragma solidity ^0.7.0;

import { TokenInterface } from "../../common/interfaces.sol";
import { Stores } from "../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract PolygonBridgeResolver is Events, Helpers {
    function deposit(
        address targetDsa,
        address token,
        uint256 amt,
        uint256 getId,
        uint256 setId
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        uint _amt = getUint(getId, amt);

        if (token == ethAddr) {
            _amt = _amt == uint(-1) ? address(this).balance : _amt;
            migrator.depositEtherFor{value: _amt}(targetDsa);
        } else {
            TokenInterface _token = TokenInterface(token);
            _amt = _amt == uint(-1) ? _token.balanceOf(address(this)) : _amt;
            _token.approve(erc20Predicate, _amt);
            migrator.depositFor(targetDsa, token, abi.encode(_amt));
        }

        setUint(setId, _amt);

        _eventName = "LogDeposit(address,address,uint256,uint256,uint256)";
        _eventParam = abi.encode(targetDsa, token, _amt, getId, setId);
    }

    /**
     * @dev Withdraw assets from Polygon.
     * @notice Complete withdraw by submitting burn tx hash.
     * @param proof The proof generated from burn tx.
    */
    function withdraw(
        bytes calldata proof
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        require(proof.length > 0, "invalid-proof");

        migrator.exit(proof);

        _eventName = "LogWithdraw(bytes)";
        _eventParam = abi.encode(proof);
    }
}

contract ConnectPolygonBridge is PolygonBridgeResolver {
    string public constant name = "COMP-v1";
}