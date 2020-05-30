pragma solidity >=0.6.0 <= 0.6.8;

contract Transfer_money {
    function send(address payable recipient) external payable {
        recipient.transfer(msg.value);
    }
}

contract Admin {
    address private owner;

    event ConstructorInitiated(string nextStep);

    uint64[4] private prices; //цены на профили

    constructor () public {
        emit ConstructorInitiated("Вызван конструктор Admin");
        owner = msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function setPrice(uint8 profile, uint64 price) public {
        require(msg.sender == owner);
        prices[profile] = price;
    }

    function getPrice(uint8 profile) external view returns(uint64) {
        return prices[profile];
    }
}

contract Main {
    address private owner;
    address payable constant bfs_wallet = 0x0da52A47b11fFFefEf609E41FCF956b52ca9a2Ef;

    uint64[4] public subs_days; // сколько дней подписки осталось
    uint256[4] public last_upd; // последнее обновление

    User user;
    Banker banker;
    Business business;
    Investor investor;
    Transfer_money tm;

    event ConstructorInitiated(string nextStep);
    event Deposit(address _sender, uint amount);
	event Withdraw(address _sender, uint amount, address recipient);

    constructor () public {
        emit ConstructorInitiated("Вызван конструктор Main");
        owner = msg.sender;
        subs_days[0] = 0; //Обычный пользователь
        subs_days[1] = 0; //Банкир
        subs_days[2] = 0; //Предприятие
        subs_days[3] = 0; //Инвестор
        last_upd[0] = now; //Обычный пользователь
        last_upd[1] = now; //Банкир
        last_upd[2] = now; //Предприятие
        last_upd[3] = now; //Инвестор
        user = new User();
        banker = new Banker();
        business = new Business();
        investor = new Investor();
        tm = new Transfer_money();
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function delDays(uint8 profile) private returns(uint256) {
        subs_days[profile] -= uint64((now - last_upd[profile]) / 86400);
        if (subs_days[profile] < 0)
            subs_days[profile] = 0;
        return subs_days;
    }

    function addDays(uint64 s_months, uint8 profile) public payable {
        Admin admin = Admin(bfs_wallet);
        uint64 price = s_months * admin.getPrice(profile);
        require(msg.value >= price);
        emit Withdraw(owner, price, bfs_wallet);
        tm.send(bfs_wallet);
        delDays(profile);
        subs_days[profile] += (s_months * 30);
        last_upd[profile] = now;
    }

    /*
    function() {
        require(isAllowedToSend(msg.sender));
		Deposit(msg.sender, msg.value);
	}
	
	function sendFunds(uint amount, address receiver) returns (uint) {
		if(isAllowedToSend(msg.sender)) {
			if(this.balance >= amount) {
				if(!receiver.send(amount)) {
					throw;
				}
				Withdraw(msg.sender, amount, receiver);
				// log each withdrawl, receiver, amount
				isAllowedToSendFundsMapping[msg.sender].amount_sends++;
				isAllowedToSendFundsMapping[msg.sender].withdrawls[isAllowedToSendFundsMapping[msg.sender].amount_sends].to = receiver;
				isAllowedToSendFundsMapping[msg.sender].withdrawls[isAllowedToSendFundsMapping[msg.sender].amount_sends].amount = amount;
				return this.balance;
			}
		}
	}

	// Allowed to send funds when the boolean mapping is set to true
	function allowAddressToSendMoney(address _address) {
		if(msg.sender == owner) {
			isAllowedToSendFundsMapping[_address].allowed = true;
		}
	}

	// Not allowed to send funds when the boolean mapping is set to false
	function disallowAddressToSendMoney(address _address) {
		if(msg.sender == owner) {
			isAllowedToSendFundsMapping[_address].allowed = false;
		}
	}

	// Check function which returns the boolean value
	function isAllowedToSend(address _address) constant returns (bool) {
		return isAllowedToSendFundsMapping[_address].allowed || _address == owner;
	}

	// check to make sure the msg.sender is the owner or it will suicide the contract and return funds to the owner
	function killWallet() {
		if(msg.sender == owner) {
			suicide(owner);
		}
	}
	*/
}

contract User {
    address private owner;

    constructor () public {
        owner = msg.sender;
    }
}

contract Banker {
    address private owner;

    constructor () public {
        owner = msg.sender;
    }
}

contract Business {
    address private owner;

    constructor () public {
        owner = msg.sender;
    }
}

contract Investor {
    address private owner;

    constructor () public {
        owner = msg.sender;
    }
}