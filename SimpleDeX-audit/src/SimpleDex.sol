// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SimpleDex
 * @author 0xArektQ
 * @notice A simple DEX implementation using constant product AMM (x * y = k)
 * @dev This contract allows users to swap between two ERC20 tokens
 */
contract SimpleDex {
    // Token pair for this DEX
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    // LP token balances
    mapping(address => uint256) public lpBalances;
    uint256 public totalLpTokens;
    
    // Token reserves
    uint256 public reserveA;
    uint256 public reserveB;
    
    // Owner of the contract
    address public owner;
    
    // Events
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool isAtoB);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @notice Constructor to initialize the DEX with token addresses
     * @param _tokenA Address of the first token
     * @param _tokenB Address of the second token
     */
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }
    
    /**
     * @notice Add liquidity to the pool
     * @param amountA Amount of tokenA to add
     * @param amountB Amount of tokenB to add
     * @return lpTokens Amount of LP tokens minted
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 lpTokens) {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");
        
        // Transfer tokens to the contract
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        // Calculate LP tokens to mint
        if (totalLpTokens == 0) {
            // First liquidity provider gets LP tokens equal to sqrt(amountA * amountB)
            lpTokens = sqrt(amountA * amountB);
        } else {
            // Subsequent providers get LP tokens proportional to their contribution
            uint256 lpTokensA = (amountA * totalLpTokens) / reserveA;
            uint256 lpTokensB = (amountB * totalLpTokens) / reserveB;
            lpTokens = lpTokensA < lpTokensB ? lpTokensA : lpTokensB;
        }
        
        // Update reserves and LP tokens
        reserveA += amountA;
        reserveB += amountB;
        lpBalances[msg.sender] += lpTokens;
        totalLpTokens += lpTokens;
        
        emit LiquidityAdded(msg.sender, amountA, amountB, lpTokens);
        return lpTokens;
    }
    
    /**
     * @notice Remove liquidity from the pool
     * @param lpTokenAmount Amount of LP tokens to burn
     * @return amountA Amount of tokenA returned
     * @return amountB Amount of tokenB returned
     */
    function removeLiquidity(uint256 lpTokenAmount) external returns (uint256 amountA, uint256 amountB) {
        require(lpTokenAmount > 0, "LP token amount must be greater than 0");
        require(lpBalances[msg.sender] >= lpTokenAmount, "Insufficient LP tokens");
        
        // Calculate token amounts to return
        amountA = (lpTokenAmount * reserveA) / totalLpTokens;
        amountB = (lpTokenAmount * reserveB) / totalLpTokens;
        
        // Update LP tokens
        lpBalances[msg.sender] -= lpTokenAmount;
        totalLpTokens -= lpTokenAmount;
        
        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;
        
        // Transfer tokens to the user
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);
        
        emit LiquidityRemoved(msg.sender, amountA, amountB, lpTokenAmount);
        return (amountA, amountB);
    }
    
    /**
     * @notice Swap tokenA for tokenB
     * @param amountIn Amount of tokenA to swap
     * @param minAmountOut Minimum amount of tokenB to receive
     * @return amountOut Amount of tokenB received
     */
    function swapAForB(uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount in must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Transfer tokenA to the contract
        tokenA.transferFrom(msg.sender, address(this), amountIn);
        
        // Calculate amount out using constant product formula (x * y = k)
        // k = reserveA * reserveB
        // (reserveA + amountIn) * (reserveB - amountOut) = k
        // amountOut = reserveB - (reserveA * reserveB) / (reserveA + amountIn)
        uint256 k = reserveA * reserveB;
        amountOut = reserveB - (k / (reserveA + amountIn));
        
        // Apply fee (0.3%)
        amountOut = (amountOut * 997) / 1000;
        
        require(amountOut >= minAmountOut, "Slippage too high");
        
        // Update reserves
        reserveA += amountIn;
        reserveB -= amountOut;
        
        // Transfer tokenB to the user
        tokenB.transfer(msg.sender, amountOut);
        
        emit Swap(msg.sender, amountIn, amountOut, true);
        return amountOut;
    }
    
    /**
     * @notice Swap tokenB for tokenA
     * @param amountIn Amount of tokenB to swap
     * @param minAmountOut Minimum amount of tokenA to receive
     * @return amountOut Amount of tokenA received
     */
    function swapBForA(uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount in must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        
        // Transfer tokenB to the contract
        tokenB.transferFrom(msg.sender, address(this), amountIn);
        
        // Calculate amount out using constant product formula (x * y = k)
        uint256 k = reserveA * reserveB;
        amountOut = reserveA - (k / (reserveB + amountIn));
        
        // Apply fee (0.3%)
        amountOut = (amountOut * 997) / 1000;
        
        require(amountOut >= minAmountOut, "Slippage too high");
        
        // Update reserves
        reserveB += amountIn;
        reserveA -= amountOut;
        
        // Transfer tokenA to the user
        tokenA.transfer(msg.sender, amountOut);
        
        emit Swap(msg.sender, amountIn, amountOut, false);
        return amountOut;
    }
    
    /**
     * @notice Get the current price of tokenA in terms of tokenB
     * @return price Price of tokenA in tokenB
     */
    function getPriceA() external view returns (uint256 price) {
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        return (reserveB * 1e18) / reserveA;
    }
    
    /**
     * @notice Get the current price of tokenB in terms of tokenA
     * @return price Price of tokenB in tokenA
     */
    function getPriceB() external view returns (uint256 price) {
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");
        return (reserveA * 1e18) / reserveB;
    }
    
    /**
     * @notice Emergency withdraw tokens in case of issues
     * @param token Address of the token to withdraw
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external {
        // No access control check here - vulnerability!
        IERC20(token).transfer(msg.sender, amount);
    }
    
    /**
     * @notice Transfer ownership of the contract
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only owner can transfer ownership");
        require(newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    /**
     * @notice Calculate square root using Babylonian method
     * @param y Number to calculate square root of
     * @return z Square root of y
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
