// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ExpenseTracker {
    struct Contributors {
        uint256 amount;
        uint256 timestamp;
    }

    struct Expense {
        string title;
        string description;
        uint256 totalAmount;
        uint256 totalContributors;
        bool isActive;
        address[] contributors;
        uint256 createdAt;
        bool paidOut; 
        mapping(address => Contributors[]) contributions;
    }

    mapping(uint256 => Expense) public expenses;
    uint256 public expenseCount;

    event ExpenseCreated(
        uint256 expId,
        string titile,
        string description,
        uint256 totalAmount,
        uint256 timestamp
    );
    event ContributionMade(
        uint256 indexed expId,
        address indexed contributor,
        uint256 amount,
        uint256 timestamp
    );
    event ExpenseSettled(
        uint256 indexed expenseId,
        uint256 totalContributors,
        uint256 timestamp
    );

    event ExpensePaidOut(
        uint256 indexed expenseId,
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );

    modifier expenseExists(uint256 _expId) {
        require(_expId < expenseCount, "Expense does not exist");
        _;
    }

    modifier expenseActive(uint256 _expenseId) {
        require(expenses[_expenseId].isActive, "Expense is not active");
        _;
    }

    function createExpense(
        string memory _title,
        string memory _description,
        uint256 _totalAmount
    ) external returns (uint256) {
        require(msg.sender != address(0), "Zero Address is not allowed");
        require(_totalAmount > 0, "Amount must be greater than 0");

        uint256 expenseId = expenseCount++;
        Expense storage newExpense = expenses[expenseId];
        newExpense.title = _title;
        newExpense.description = _description;
        newExpense.totalAmount = _totalAmount;
        newExpense.createdAt = block.timestamp;
        newExpense.isActive = true;

        emit ExpenseCreated(
            expenseId,
            _title,
            _description,
            _totalAmount,
            block.timestamp
        );
        return expenseId;
    }

    function contribute(
        uint256 _expId
    ) external payable expenseExists(_expId) expenseActive(_expId) {
        require(msg.value > 0, "Contribution must be greater than 0");

        Expense storage expense = expenses[_expId];

        bool hasContributedBefore = false;

        if (expense.contributors.length > 0) {
            if (expense.contributions[msg.sender].length > 0) {
                hasContributedBefore = true;
            }
        }

        if (!hasContributedBefore) {
            expense.contributors.push(msg.sender);
        }

        expense.contributions[msg.sender].push(
            Contributors({amount: msg.value, timestamp: block.timestamp})
        );

        expense.totalContributors += msg.value;

        emit ContributionMade(_expId, msg.sender, msg.value, block.timestamp);

        if (expense.totalContributors >= expense.totalAmount) {
            expense.isActive = false;
            emit ExpenseSettled(
                _expId,
                expense.totalContributors,
                block.timestamp
            );
        }
    }

    function getExpenseDetails(
        uint256 _expenseId
    )
        external
        view
        expenseExists(_expenseId)
        returns (
            string memory title,
            string memory description,
            uint256 totalAmount,
            uint256 totalContributed,
            uint256 createdAt,
            bool isActive,
            address[] memory contributors
        )
    {
        Expense storage expense = expenses[_expenseId];
        return (
            expense.title,
            expense.description,
            expense.totalAmount,
            expense.totalContributors,
            expense.createdAt,
            expense.isActive,
            expense.contributors
        );
    }

    function getContributions(
        uint256 _expenseId,
        address _contributor
    )
        external
        view
        expenseExists(_expenseId)
        returns (uint256[] memory amounts, uint256[] memory timestamps)
    {
        Contributors[] storage contributions = expenses[_expenseId]
            .contributions[_contributor];

        if (contributions.length == 0) {
            return (new uint256[](0), new uint256[](0));
        } else {
            amounts = new uint256[](contributions.length);
            timestamps = new uint256[](contributions.length);

            amounts[0] = contributions[0].amount;
            timestamps[0] = contributions[0].timestamp;

            if (contributions.length > 1) {
                amounts[1] = contributions[1].amount;
                timestamps[1] = contributions[1].timestamp;
            }

            return (amounts, timestamps);
        }
    }


    function getTotalContribution(
        uint256 _expenseId,
        address _contributor
    ) external view expenseExists(_expenseId) returns (uint256 total) {
        Contributors[] storage contributions = expenses[_expenseId]
            .contributions[_contributor];
        for (uint256 i = 0; i < contributions.length; i++) {
            total += contributions[i].amount;
        }
        return total;
    }
    

    function withdraw(uint256 _expenseId) external expenseExists(_expenseId) {
        Expense storage expense = expenses[_expenseId];

        require(!expense.isActive, "Expense is still active");
        require(!expense.paidOut, "Expense already paid out");
        require(
            expense.totalContributors >= expense.totalAmount,
            "Target amount not reached"
        );

        uint256 payoutAmount = expense.totalContributors;
        expense.paidOut = true;

        (bool sent, ) = payable(msg.sender).call{value: payoutAmount}("");
        require(sent, "Failed to send funds");

        emit ExpensePaidOut(
            _expenseId,
            msg.sender,
            payoutAmount,
            block.timestamp
        );
    }
}
