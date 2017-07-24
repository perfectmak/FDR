pragma solidity ^0.4.0;

contract Campaign {

    address public beneficiary;

    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;

    mapping(address => uint256) public balanceOf;

    bool fundingGoalReached = false;
    // Events that will be fired on changes.
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution); // log the fund transfer
    event Refund(address _to, uint _amount); // possible refund if the target is not met

    bool campaignClosed = false;

    /* data structure to hold information about campaign contributors */
    struct Contributor {
        uint received;
        uint returned;
        uint contributorListPointer;
    }

    // the array of individuals who have donated to this fundraising
    mapping(address => Contributor) public contributorStructs;

    address[] public contributorList;

    /*  at initialization, setup the owner */
    function Campaign(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        token addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        // we will modify this along the line
        price = etherCostOfEachToken * 1 ether;
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier afterDeadline() {
        if (now >= deadline)
        _;
    }

    function getContributorCount()
        public
        constant
        returns(uint contributorCount)
    {
        return contributorList.length;
    }

    function isContributor(address contributor)
        public
        constant
        returns(bool isIndeed)
    {
        if(contributorList.length==0) return false;
        return contributorList[contributorStructs[contributor].contributorListPointer]==contributor;
    }


    /* The function that is called whenever anyone sends funds to a contract */
    function contribute() payable
        condition(msg.value > 0.00000000)
        returns(bool success)
    {
        // don't accept transaction if the campaign has closed
        if (campaignClosed){
            throw;
        }
        // Revert the call to contribute if the fund raising
        // period is over
        require(now <= deadline);

        // push new contributor, update existing
        if(!isContributor(msg.sender)) {
            contributorStructs[msg.sender].contributorListPointer = contributorList.push(msg.sender)-1;
        }

        uint amount = msg.value;
        balanceOf[msg.sender] = amount;
        amountRaised += amount;

        donorsPaid[msg.sender] = msg.value;

        // keep track of receipt for contributors
        contributorStructs[msg.sender].received += msg.value;
        FundTransfer(msg.sender, amount, true);
        return true;
    }


    /*
     refund the funds to the donors if the target is not met or the fund raise is cancelled
     or flagged not to be genuine
    */
    function refund(uint amount) public {
        if (msg.sender != beneficiary) {
            return;
        }
        uint currentBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        if (currentBalance > 0 && currentBalance >= amount) {
            if (msg.sender.send(amount)) {
                FundTransfer(msg.sender, amount, false);
            } else {
                // update the balance for the contributor
                balanceOf[msg.sender] = currentBalance - amount;
            }
        }
        return;
    }

    /* checks if the goal or time limit has been reached and ends the campaign */
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        campaignClosed = true;
    }

    // either reduce or increase the set deadline for the fund raise
    function changeDeadline(uint newDeadline) private
        returns(bool success)
    {
        if(now >= newDeadline || deadline >= newDeadline) {
            return false;
        }
        // update the existing deadline
        deadline = newDeadline;
        return true;
    }


    function withdraw() afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock contributors balance
                fundingGoalReached = false;
            }
        }
    }

    // retrieve the total amount donated thus far
    function getTotalDonation()
        public
        constant
        returns(uint)
    {
        return amountRaised;
    }

    // retrieve the addresses of donors on this fund raise
    function getDonors()
        public
        constant
        returns(address[])
    {
        return contributorList;
    }

    // release funds in the contract to avoid permanent lockdown
    function destroy() {
        if(msg.sender == beneficiary) {
            selfdestruct(beneficiary);
        }
    }

}
