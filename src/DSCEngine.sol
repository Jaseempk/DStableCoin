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


    ////////////
   ///Error ///
  ////////////
error DSCEngine__AmountMustBeMoreThanZero();
error DSCEngine___TokenAddressAndPriceFeedAddressNotSameLength();
error DSCEngine__CollateralNotSupported();
  

contract DSCEngine{

    /////////// 
   // state // 
   //////////

mapping(address token => address priceFeed) public s_priceFeed;
mapping(address user => mapping(address token => uint256 amount)) public s_CollateralDeposited;


DStableCoin private immutable i_dsc;

    ////////////////
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
    reentrant
    moreThanZero(_collateralTokenAmount) 
    onlyAssignedCollateral(_collateralTokenAddress){

        s_CollateralDeposited[msg.sender][_collateralTokenAddress]+=_collateralTokenAmount;

        IERC20(_collateralTokenAddress).transferFrom(msg.sender,address(this),_collateralTokenAmount);



    }

    function mintDSC(uint256 amount)external{

        revertIfLowHealthFactor();
    }

    function burnDSC()external{}

    function liquidate()external{}


     ///////////////////////////
    // Public&External View ///
   ///////////////////////////


     

    function healthFactor(uint256 collateralValueUsd) external view returns(uint256){

    }


    function revertIfLowHealthFactor()public view{
        healthFactor();
    }


}