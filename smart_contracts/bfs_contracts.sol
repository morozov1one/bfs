pragma solidity >=0.6.0 <= 0.6.8;

import "github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol";

contract Main {
    address private owner;
    address payable constant bfs_wallet = 0x0da52A47b11fFFefEf609E41FCF956b52ca9a2Ef;
    //private uint32 user_id;
    
    event ConstructorInitiated(string nextStep);
    event Deposit(address _sender, uint amount);
	event Withdraw(address _sender, uint amount, address recipient);
    
    constructor () public {
        emit ConstructorInitiated("Вызван конструктор Main");
        owner = msg.sender;
        //uder_id = id;
    }
    
    function getOwner() external view returns (address) {
        return owner;
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

contract Money_Oracle is usingProvable {
    //В текущий версии цена на день подписки устанавливается жёстко (прямо тут), в долларах
    uint64 constant user_price = 1; //Обычный пользователь
    uint64 constant banker_price = 10; //Банкир
    uint64 constant business_price = 50; //Предприятие
    uint64 constant investor_price = 2; //Инвестор
    
    string public ETHUSD;
    
    event ConstructorInitiated(string nextStep);
    event PriceUpdated(string price);
    event NewProvableQuery(string description);
    
    constructor() public payable {
        emit ConstructorInitiated("Вызван конструктор Money_Oracle");
    }
    
    function callback(bytes32 myid, string memory result) public {
        if (msg.sender != provable_cbAddress()) 
            revert();
        ETHUSD = result;
        PriceUpdated(result);
    }
    
    function stringToUint(string memory s) private returns (uint64) {
        bytes memory b = bytes(s);
        uint64 result = 0;
        for (uint8 i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }
    
    function updatePrice() public payable returns(uint64) {
       if (provable_getPrice("URL") > address(this).balance) {
           NewProvableQuery("Provable query was NOT sent, please add some ETH to cover for the query fee");
           return 0;
       } 
       else {
           NewProvableQuery("Provable query was sent, standing by for the answer..");
           provable_query("URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price");
           return stringToUint(ETHUSD);
       }
   }
   
   function getPrice() public returns(uint64) {
        uint64 eth_usd = 0;
        while (eth_usd == 0) {
            emit ConstructorInitiated("ИТЕРАЦИЯ");
            eth_usd = updatePrice();
        }
        return user_price * 1000000000000000000 / eth_usd;
   }
}

contract Transfer_money {
    function send(address payable recipient) external payable {
        recipient.transfer(msg.value);
    }
}

contract User is Main {
    address private owner;
    uint64 private subs_days; // сколько дней подписки осталось
    
    event ConstructorInitiated(string nextStep);
    event Deposit(address _sender, uint amount);
	event Withdraw(address _sender, uint amount, address recipient);
    
    constructor (uint32 s_days) public {
        emit ConstructorInitiated("Вызван конструктор User");
        owner = msg.sender;
        subs_days = s_days;
    }
    
    function addDays(uint64 s_months) public payable {
        Money_Oracle mo = new Money_Oracle();
        uint64 price = s_months * mo.getPrice();
        require(msg.value >= price);
        emit Withdraw(owner, price, bfs_wallet);
        Transfer_money tm = new Transfer_money();
        tm.send(bfs_wallet);
        subs_days += (s_months * 30);
    }
    
    function getPrice() public returns(uint64) {
        Money_Oracle mo = new Money_Oracle();
        return mo.getPrice();
    }
}

contract Banker {
    
}

contract Business {
    
}

contract Investor {
    
}