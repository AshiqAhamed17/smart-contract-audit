// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.19;

import "./OperatorAdminable.sol";

abstract contract Pausable is OperatorAdminable {
    bool public paused;

    event Paused();
    event Resumed();

    constructor(address _admin) Adminable(_admin) {}

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    function pause() external onlyAdmin {
        paused = true;
        emit Paused();
    }

    function resume() external onlyAdmin {
        paused = false;
        emit Resumed();
    }
}