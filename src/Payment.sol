// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Payment {
    error Payment__PaymentAmountMustBeGreaterThanZero();
    error Payment__FailedToSendEther();
    error Payment__InvalidReceiverAddress();
    error Payment__ArrayLengthMismatch();
    error Payment__NotEnoughEtherSent();

    address public constant OWNER = 0x61ec9Cbc365b23eC035986A30FDed12e94756b3B;
    uint256 public constant FEE_PERCENTAGE = 3; // 3%

    function sendPayment(address[] calldata recipients, uint256[] calldata amounts) external payable {
        if (recipients.length != amounts.length) {
            revert Payment__ArrayLengthMismatch();
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        if (msg.value < totalAmount) {
            revert Payment__NotEnoughEtherSent();
        }

        uint256 totalEtherSentToRecipients = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) {
                revert Payment__InvalidReceiverAddress();
            }

            if (amounts[i] == 0) {
                revert Payment__PaymentAmountMustBeGreaterThanZero();
            }

            uint256 fee = (amounts[i] * FEE_PERCENTAGE) / 100;
            uint256 amountToSendToRecipient = amounts[i] - fee;
            totalEtherSentToRecipients += amountToSendToRecipient;
            (bool sentToReceiver,) = recipients[i].call{value: amountToSendToRecipient}("");
            if (!sentToReceiver) {
                revert Payment__FailedToSendEther();
            }
        }

        (bool sentToOwner,) = OWNER.call{value: msg.value - totalEtherSentToRecipients}("");
        if (!sentToOwner) {
            revert Payment__FailedToSendEther();
        }
    }

    receive() external payable {
        (bool sentToOwner,) = OWNER.call{value: msg.value}("");
        if (!sentToOwner) {
            revert Payment__FailedToSendEther();
        }
    }

    fallback() external payable {
        (bool sentToOwner,) = OWNER.call{value: msg.value}("");
        if (!sentToOwner) {
            revert Payment__FailedToSendEther();
        }
    }
}
