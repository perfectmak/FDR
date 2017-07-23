pragma solidity ^0.4.0;


contract Campaign {

    // the individual raising funds
    address public raiser;
    // the array of individuals who have donated to this fundraising
    mapping (address => uint) public donorsPaid;
    // total number of Donors so far
    uint public numDonors;
    // the deadline
    uint public fundDeadline;
    // the target to be met with this fundraising
    uint public fundTarget;
    // Set to true at the end, disallows any change
    bool ended;

    // Events that will be fired on changes.
    event FundRaiseEnded(address raiser, uint _amount);
    event FundRaiseTargetMet(address raiser, uint _amount);
    event Deposit(address _from, uint _amount); // log the deposit
    event Refund(address _to, uint _amount); // possible refund if the target is not met

    function Campaign() {
        raiser = msg.sender;
        fundTarget = 100;
        numDonors = 0;
    }

    // contribute to ongoing fund raise
    function contributeToFundRaise() public {
        // check if deadline hasn't been exceeded
        if (now > fundDeadline ) {
            throw; // throw ensures funds will be returned
        }
        donorsPaid[msg.sender] = msg.value;
        numDonors++;
        Deposit(msg.sender, msg.value);
    }

    // get back donation that was made to the campaign
    function withdrawDonation() returns (bool) {
        var amount = pendingReturns[msg.sender];
        if (amount > 0) {
            /**
              * It is important to set this to zero because the recipient
              * can call this function again as part of the receiving call
              * before `send` returns.
              */
            pendingReturns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // either reduce or increase the set deadline for the fund raise
    function changeDeadline() private {

    }

    /** @dev change the target amount to meet for the fund raise
     * @param amount the new amount to be set as target
     */
    function changeFundTarget(uint amount) private {
        if (msg.sender != raiser) {
            return;
        }
        // set the new target to be the new amount
        fundTarget = amount;
    }

    /*
     refund the funds to the donors if the target is not met or the fund raise is cancelled
     or flagged not to be genuine
    */
    function refundDonation(address recipient, uint amount) public {
        if (msg.sender != raiser) {
            return;
        }
        if (donorsPaid[recipient] == amount) {
            address myAddress = this;
            if (myAddress.balance >= amount) {
                recipient.send(amount);
                Refund(recipient, amount);
                donorsPaid[recipient] = 0;
                numDonors--;
            }
        }
        return;
    }

    // retrieve the total amount donated thus far
    function getTotalDonation() public {

    }

    // retrieve the addresses of donors on this fund raise
    function getDonors() public {

    }

    // release funds in the contract to avoid permanent lockdown
    function destroy() {
        if(msg.sender == raiser) {
            suicide(raiser);
        }
    }

}
