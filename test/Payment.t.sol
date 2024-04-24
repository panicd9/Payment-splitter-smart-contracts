// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Payment} from "../src/Payment.sol";

contract PaymentTest is Test {
    Payment public payment;
    address public SENDER = makeAddr("SENDER");
    address public RECEIVER1 = makeAddr("RECEIVER1");
    address public RECEIVER2 = makeAddr("RECEIVER2");
    address public RECEIVER3 = makeAddr("RECEIVER3");
    address public RECEIVER4 = makeAddr("RECEIVER4");

    function setUp() public {
        payment = new Payment();
    }

    function test_Payment(uint256[4] memory amounts) public {
        for (uint256 i = 0; i < amounts.length; i++) {
            vm.assume(amounts[i] > 0);
            vm.assume(amounts[i] < type(uint248).max);
        }

        uint256 totalExpectedFeesPaid = 0;
        uint256[4] memory expectedAmountSentToRecipient;
        uint256 totalAmount = 0;
        uint256 expectedTotalAmountSentToRecipients = 0;

        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
            uint256 expectedFeeToPay = (amounts[i] * payment.FEE_PERCENTAGE()) / 100;
            totalExpectedFeesPaid += expectedFeeToPay;
            expectedAmountSentToRecipient[i] = amounts[i] - expectedFeeToPay;
            expectedTotalAmountSentToRecipients += expectedAmountSentToRecipient[i];
        }
        deal(SENDER, totalAmount + 1e18);

        address[] memory recipients = new address[](4);
        recipients[0] = RECEIVER1;
        recipients[1] = RECEIVER2;
        recipients[2] = RECEIVER3;
        recipients[3] = RECEIVER4;

        uint256[] memory amountsToSend = new uint256[](4);
        amountsToSend[0] = amounts[0];
        amountsToSend[1] = amounts[1];
        amountsToSend[2] = amounts[2];
        amountsToSend[3] = amounts[3];

        vm.prank(SENDER);
        payment.sendPayment{value: totalAmount + 1e18}(recipients, amountsToSend);

        console.log("Payment balance: ", address(payment).balance);

        for (uint256 i = 0; i < amounts.length; i++) {
            assertEq(recipients[i].balance, expectedAmountSentToRecipient[i]);
        }

        assertEq(payment.OWNER().balance, totalAmount + 1e18 - expectedTotalAmountSentToRecipients);
    }
}
