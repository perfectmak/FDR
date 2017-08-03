// Include web3 library so we can query accounts.
var web3 = require('ethereum.js');
// Instantiate new web3 object pointing toward an Ethereum node.
// var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
web3.setProvider(new web3.providers.HttpProvider('http://localhost:8545'));
// Include Campaign contract
var Campaign = artifacts.require("./Campaign.sol");

// Test with Mocha
contract('Campaign', function(accounts) {
    var beneficiary = accounts[0];
    var account_one = accounts[1];
    var account_two = accounts[2];
    // hold the campaign object
    var campaign;
    var id;

    // A convenience to view account balances in the console before making changes.
    printBalances(accounts);
    // Create a test case for retrieving the deployed contract.
    // We pass 'done' to allow us to step through each test synchronously.
    it("Should retrieve deployed contract.", function(done) {
        // Check if our instance has deployed
        Campaign.deployed().then(function(instance) {
            // Assign our contract instance for later use
            campaign = instance;
            console.log('campaign', campaign);
            // Pass test if we have an object returned.
            assert.isOk(campaign);
            // Tell Mocha move on to the next sequential test.
            done();
        });
    });

    // Test for depositing 1 Ether
    it("Should deposit 1 ether.", function(done) {
        // Call the donate method on the contract. Since that method is tagged payable,
        // we can send Ether by passing an object containing from, to and amount.
        // All transactions are carried sent in wei. We use a web3 utility to convert from Ether.
        campaign.contribute({from:account_two, to:campaign.beneficiary, value: web3.toWei(1, "ether")})
            .then(function(tx) {
                // Pass the test if we have a transaction receipt returned.
                assert.isOk(tx.receipt);
                console.log(tx.receipt);
                // For convenience, show the balances of accounts after transaction.
                // printBalances(accounts);
                done();
            }, function(error) {
                // Force an error if callback fails.
                // assert(false, false);
                console.error(error);
                done();
            });
    });

    // Utility function to display the balances of each account.
    function printBalances(accounts) {
        accounts.forEach(function(ac, i) {
            console.log(i, web3.fromWei(web3.eth.getBalance(ac), 'ether').toNumber());
        });
    }

    // test the halt function when the person attempting to modify is not the owner
    it("should halt if action is performed by the owner", function () {
        return Campaign.deployed().then(function (instance) {
            campaign = instance;
            return campaign.halt.call(account_two)
                .then(function(account_two) {
                    assert.notEqual(beneficiary, account_two, "Campaign cannot be halted by this user");
                });
        });
    });

    // test the halt function with the owner modifying
    it("should halt if action is performed by the owner", function () {
        return Campaign.deployed().then(function (instance) {
            campaign = instance;
            return campaign.halt.call(account_one)
                .then(function(address) {
                    assert.notEqual(beneficiary, account_one, "Campaign cannot be halted by this user");
                });
        });
    });

    // test the unhalt function
    it("should unhalt if action is performed by the owner", function () {
        return Campaign.deployed().then(function (instance) {
            campaign = instance;
            return campaign.unhalt.call(account_two)
                .then(function(owner) {
                    assert.equal(owner, false, "Campaign cannot be unhalted by this user");
                });
        });
    });


    // test the isContributor method
    it("should return true if the address owner is the same as the contributor", function () {
        Campaign.deployed().then(function(instance) {
            campaign = instance;
            return campaign.isContributor.call(account_one)
                .then(function(address) {
                    "use strict";
                    assert.notEqual(beneficiary, account_one, "The address of the sender is the one of the contributors")
                });
        });
    });


    // test the getTotalDonation method
    it("should return the total amount donated for the campaign", function () {
        Campaign.deployed().then(function(instance) {
                return instance.getDetails.call(id);
            })
            .then(function(details) {
                console.log(details);
            });
    });


    it("should contribute to an ongoing campaign", function() {
        return Campaign.deployed().then(function(instance) {
            campaign = instance;
            return campaign.contribute.call(account_one, campaign)
                .then(function (campaignID) {
                    id = campaignID;
                    console.log(id);
                    return campaign.contribute(id, {from: account_one, value: 1});
                })
                .then(function() {
                    assert.equal(web3.eth.getBalance(campaign.address).toNumber(), 1, "Balance isn't 1 after one contribution of 1");
                    return campaign.checkGoalReached.call();
                })
                .then(function(reached) {
                    assert.equal(reached, false, "Campaign with goal 2 is reached with balance 1");
                });
        });
    });




});
