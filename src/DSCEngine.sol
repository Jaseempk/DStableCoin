//SPDX-License-Identifier:MIT
// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


pragma solidity ^0.8.18;


import {DStableCoin} from "./DStableCoin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


    ////////////
   /// Error///
  ////////////
error DSCEngine__AmountMustBeMoreThanZero();
error DSCEngine___TokenAddressAndPriceFeedAddressNotSameLength();
error DSCEngine__CollateralNotSupported();
error DSCEngine__DepositFailed();
error DSCEngine__NeedBetterHealthFactor();
  

contract DSCEngine{

    /////////// 
   // state // 
   //////////
uint256 private constant PRECISION=1e10;
uint256 private constant ANOTHER_PRECISION=100;
uint256 private constant LIQUIDATION_THRESHOLD=50;
uint256 private constant LIQUIDATION_PRECISION=100;
uint256 private constant MINIMUM_HEALTH_FACTOR=1;


mapping(address token => address priceFeed) public s_priceFeed;
mapping(address user => mapping(address token => uint256 amount)) public s_CollateralDeposited;
mapping(address user => uint256 dscTokenMinted) public s_DSCMinted;
address[] public s_tokenCollateralAmount;


DStableCoin private immutable i_dsc;


     ////////////
    // Events //
   ////////////
   event CollateralDepositted(address indexed user,address indexed token, uint256 indexed amount);


     ///////////////
    // Modifiers //
   ///////////////
   modifier moreThanZero(uint256 amount){
            if(amount<=0){
            revert DSCEngine__AmountMustBeMoreThanZero();
        }
        _;
   }

    modifier onlyAssignedCollateral(address token){

        if(s_priceFeed[token]==address(0)){
            revert DSCEngine__CollateralNotSupported();
        }
        _;

    }

    ////////////////
    // Functions //
    ///////////////

    constructor(
    address[] memory s_tokenAddresses,
    address[] memory s_priceFeedAddresses,
    address dscAddress
    ){
        if(s_tokenAddresses.length!=s_priceFeedAddresses.length){
            revert DSCEngine___TokenAddressAndPriceFeedAddressNotSameLength();
        }
        for (uint256  i=0;i<s_tokenAddresses.length;i++){

            s_priceFeed[s_tokenAddresses[i]]=s_priceFeedAddresses[i];

            s_tokenCollateralAmount.push(s_tokenAddresses[i]);

        }
        i_dsc=DStableCoin(dscAddress);
    }


    /////////////////////////
    // External Functions //
    ///////////////////////

    function depositeCollateralAndMintDSC()external{}

    function redeemDSC()external{}

    function depositeCollateral(address _collateralTokenAddress,uint256 _collateralTokenAmount)
    external 
    moreThanZero(_collateralTokenAmount) 
    onlyAssignedCollateral(_collateralTokenAddress){

        s_CollateralDeposited[msg.sender][_collateralTokenAddress]+=_collateralTokenAmount;
        emit CollateralDepositted(msg.sender,_collateralTokenAddress,_collateralTokenAmount);
        (bool success)=IERC20(_collateralTokenAddress).transferFrom(msg.sender,address(this),_collateralTokenAmount);
        if(!success){
            revert DSCEngine__DepositFailed();
        }



    }

    function mintDSC(uint256 amountDSCToMint)external{

        revertIfLowHealthFactor(msg.sender);
        i_dsc.mint(msg.sender,amountDSCToMint);
    }

    function burnDSC()external{}

    function liquidate()external{}


     ////////////////////////////
    // Private&Internal View ///
   ////////////////////////////


    function getAccountInformation(address user) internal view returns(uint256 totalDSCMinted,uint256 collateralValueInUSD){
        totalDSCMinted=s_DSCMinted[user];
        collateralValueInUSD=getCollateralValueUSD(user);

    }
   

    function healthFactor(address user) internal view returns(uint256){

        (uint256 totalDSCMinted,uint256 collateralValueInUSD)=getAccountInformation(user);

        uint256 collateralAdjustedForThreshold=(collateralValueInUSD*LIQUIDATION_THRESHOLD)/LIQUIDATION_PRECISION;
        return(collateralAdjustedForThreshold*PRECISION)/totalDSCMinted;

        


    }


    function revertIfLowHealthFactor(address user)internal view{
        if(healthFactor(user)<=MINIMUM_HEALTH_FACTOR){
            revert DSCEngine__NeedBetterHealthFactor();
        }
    }



     ////////////////////////////
    // Public&External View  ///
   ////////////////////////////
    function getCollateralValueUSD(address user)public view returns(uint256 collateralValueInUSD){
        //first take the amount of collateral deposited,then get the price of the collateral
        //then multiply both of them
        for(uint256 i=0;i<s_tokenCollateralAmount.length;i++){
            
           address  token =s_tokenCollateralAmount[i];
           uint256 amount=s_CollateralDeposited[user][token];

         collateralValueInUSD+= getTheUsdPrice(token,amount);
        }
        return collateralValueInUSD;

    }

    function getTheUsdPrice(address token,uint256 amount)public view returns(uint256){
        AggregatorV3Interface  priceFeed=AggregatorV3Interface(s_priceFeed[token]);
        (,int256 price,,,)=priceFeed.latestRoundData();

        return ((uint256(price)*PRECISION*amount)/ANOTHER_PRECISION);

    }
}