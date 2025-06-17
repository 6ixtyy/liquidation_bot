// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";


interface IUniswapAnchoredView {
    function price(string memory symbol) external view returns (uint);
    function postPrices(
        bytes[] calldata messages,
        bytes[] calldata signatures,
        string[] calldata symbols
    ) external;
}
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface CErc20 {
    function mint(uint256) external returns (uint256);
    function borrow(uint256) external returns (uint256);
    function repayBorrow(uint256) external returns (uint256);
    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint);
}

interface Comptroller {
    function enterMarkets(address[] calldata) external returns (uint256[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
}

contract TokenPriceTest is Test {
    IUniswapAnchoredView public uniswapAnchoredView;
    address public constant UNISWAP_ANCHORED_VIEW = 0x9B8Eb8b3d6e2e0Db36F41455185FEF7049a35CaE; // Mainnet address
    address public constant REPORTER = 0x8329F48Bd4c7A1Cf43a434ddA99A96c605d6bf7b;
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    CErc20 constant cUSDC = CErc20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    Comptroller constant COMPTROLLER = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    IERC20 constant cETH = IERC20(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    CErc20 constant cDAI = CErc20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address constant BORROWER = 0x26DB83C03F408135933b3cFF8b7adc6A7e0ADEbc;

    function setUp() public {
        // Fork mainnet at the specified block number
        vm.createSelectFork("mainnet");
        vm.rollFork(10692539);
        deal(address(DAI), address(this), 1000000 * 1e18);
        
        // Set up the UniswapAnchoredView interface
        uniswapAnchoredView = IUniswapAnchoredView(UNISWAP_ANCHORED_VIEW);
    }
    function testTokenPrices() public {
        // Check initial state
        checkAccountLiquidity();
        checkPrices();

        // Simulate postPrices call
        simulatePostPrices();

        // Check updated state
        checkAccountLiquidity();
        checkPrices();

        // Attempt liquidation
        tryLiquidation();
    }


    function simulatePostPrices() public {
        // Prepare the call data
        bytes[] memory messages = new bytes[](2);
        messages[0] = hex"0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000005f3d826800000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000017afc4380000000000000000000000000000000000000000000000000000000000000006707269636573000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034554480000000000000000000000000000000000000000000000000000000000";
        messages[1] = hex"0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000005f3d826800000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000f5caf0000000000000000000000000000000000000000000000000000000000000006707269636573000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034441490000000000000000000000000000000000000000000000000000000000";

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = hex"d0ba2ec311667df4c2bec668b5666ce952d1373154d0393b01d937d26e19533d603ccf65290fa9b475064f039a41398954706c9417781de51a112fdd4d283c3d000000000000000000000000000000000000000000000000000000000000001b";
        signatures[1] = hex"fa8211125a669ec79f429a412aca359e411866c4bd35d7ab0bdb7749585726327c72e5fbd9e79fee3b185a89ad228090a7026058b572ea3e3e1c0038ec97686f000000000000000000000000000000000000000000000000000000000000001b";

        string[] memory symbols = new string[](2);
        symbols[0] = "ETH";
        symbols[1] = "DAI";

        // Impersonate the reporter
        vm.startPrank(REPORTER);

        // Make the call
        uniswapAnchoredView.postPrices(messages, signatures, symbols);
        // Stop impersonating
        vm.stopPrank();
    }
    function checkAccountLiquidity() private view {
        (uint err, uint liquidity, uint shortfall) = COMPTROLLER.getAccountLiquidity(BORROWER);
        require(err == 0, "Error getting account liquidity");
        console.log("Account Liquidity:", liquidity);
        console.log("Account Shortfall:", shortfall);
    }

    function checkPrices() view private {
        uint256 ethPrice = uniswapAnchoredView.price("ETH");
        uint256 daiPrice = uniswapAnchoredView.price("DAI");
        console.log("ETH price:", ethPrice);
        console.log("DAI price:", daiPrice);
    }

    function tryLiquidation() public {
        uint borrowBalance = cDAI.borrowBalanceCurrent(BORROWER);
        console.log("Borrow Balance:", borrowBalance);

        uint repayAmount = borrowBalance / 2;  // Can only liquidate up to 50% of the borrow
        console.log("Attempting to liquidate with repay amount:", repayAmount);

        DAI.approve(address(cDAI), repayAmount);
        
        uint initialDAIBalance = DAI.balanceOf(address(this));
        uint initialCETHBalance = cETH.balanceOf(address(this));

        uint result = cDAI.liquidateBorrow(BORROWER, repayAmount, address(cETH));
        
        console.log("Liquidation result:", result);
        console.log("DAI spent:", initialDAIBalance - DAI.balanceOf(address(this)));
        console.log("cETH received:", cETH.balanceOf(address(this)) - initialCETHBalance);
    }



    }
    
