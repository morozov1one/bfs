pragma solidity >=0.6.0 <= 0.6.8;

import "github.com/morozov1one/bfs/blob/master/solidity/source/Admin.sol";

contract Transfer_money {
    function send(address payable recipient) external payable {
        recipient.transfer(msg.value);
    }
}

contract Main {
    address private owner;
    address payable constant bfs_wallet = 0x0da52A47b11fFFefEf609E41FCF956b52ca9a2Ef;
    address constant admin_address = 0x3b1C4370D52692dFfbe0cFC9C2cc0935b0d0f747;
    
    uint64[4] private subs_days; //how many subscription days are left
    uint256[4] private last_upd; //latest update
    
    User private user;
    Banker private banker;
    Business private business;
    Investor private investor;
    Transfer_money private tm;
    
    event ConstructorInitiated(string nextStep);
    event Deposit(address _sender, uint amount);
	event Withdraw(address _sender, uint amount, address recipient);
    
    constructor () public {
        emit ConstructorInitiated("constructor Main");
        Admin admin = Admin(admin_address);
        require(!admin.checkUser(msg.sender));
        owner = msg.sender;
        subs_days[0] = 0;
        subs_days[1] = 0;
        subs_days[2] = 0;
        subs_days[3] = 0;
        last_upd[0] = now;
        last_upd[1] = now;
        last_upd[2] = now;
        last_upd[3] = now;
        tm = new Transfer_money();
    }
    
    function createProfiles() public {
        require(msg.sender == owner);
        user = new User(address(this));
        banker = new Banker(address(this));
        business = new Business(address(this));
        investor = new Investor(address(this));
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
    function getAddress() external view returns(address) {
        return address(this);
    }
    
    function getUserAddress() external view returns(address) {
        return address(user);
    }
    
    function getBankerAddress() external view returns(address) {
        return address(banker);
    }
    
    function getBusinessAddress() external view returns(address) {
        return address(business);
    }
    
    function getInvestorAddress() external view returns(address) {
        return address(investor);
    }
    
    function getDays(uint8 profile) public view returns(uint64) {
        return subs_days[profile];
    }

    function delDays(uint8 profile) public returns(uint256) {
        subs_days[profile] -= uint64((now - last_upd[profile]) / 86400);
        if (subs_days[profile] < 0)
            subs_days[profile] = 0;
    }

    function addDays(uint64 s_months, uint8 profile) public payable {
        Admin admin = Admin(admin_address);
        uint64 price = s_months * admin.getPrice(profile);
        require(msg.value >= price);
        emit Withdraw(owner, price, bfs_wallet);
        tm.send(bfs_wallet);
        delDays(profile);
        subs_days[profile] += (s_months * 30);
        last_upd[profile] = now;
    }
}

contract User {
    address private owner;
    address main_address;
    Transfer_money tm;
    
    constructor (address main) public {
        owner = msg.sender;
        tm = new Transfer_money();
        main_address = main;
    }
    
    function checkSubs(address user, uint8 profile) public returns(bool) {
        Main u = Main(user);
        u.delDays(profile);
        return (u.getDays(profile) > 0);
    }
    
    function sendMoney(address payable recipient) public payable {
        require(checkSubs(main_address, 0));
        tm.send(recipient);
    }
    
    function setDeposit(address banker) public payable {
        require(checkSubs(main_address, 0));
        Banker b = Banker(banker);
        b.setDeposit(main_address);
    }
    
    function getMoneyFromDeposit(address banker) public payable {
        require(checkSubs(main_address, 0));
        Banker b = Banker(banker);
        b.getMoneyFromDeposit(main_address);
    }
    
    function askCredit(address banker, uint256 value, uint8 percent, uint64 term) public {
        require(checkSubs(main_address, 0));
        Banker b = Banker(banker);
        b.askCredit(main_address, value, percent, term);
    }
    
    function payCredit(address banker) external payable {
        require(checkSubs(main_address, 0));
        Banker b = Banker(banker);
        b.payCredit(main_address);
    }
}

contract Banker {
    address private owner;
    address constant admin_address = 0x3b1C4370D52692dFfbe0cFC9C2cc0935b0d0f747;
    address main_address;
    Transfer_money tm;
    
    struct debt {
        uint256 value;
        uint8 percent;
        uint64 term;
        uint256 last_pay;
    }
    
    struct deposit {
        bool open;
        uint256 value;
        uint8 percent;
        uint16 term;
        uint256 last_upd;
    }
    
    address[] private list_of_credits;
    mapping(address => deposit) private deposits;
    mapping(address => debt) private credits;
    mapping(address => debt) private ask_credits;
    address payable[] private list_of_deposits;
    
    constructor (address main) public {
        owner = msg.sender;
        tm = new Transfer_money();
        main_address = main;
    }
    
    function checkSubs(address user, uint8 profile) public returns(bool) {
        Main u = Main(user);
        u.delDays(profile);
        return (u.getDays(profile) > 0);
    }
    
    function getDeposit(address client, uint8 percent, uint16 term) public {
        require(msg.sender == owner);
        require(checkSubs(main_address, 1));
        require(term > 0);
        deposits[client].open = true;
        deposits[client].last_upd = now;
        deposits[client].percent = percent;
        deposits[client].term = term;
    }
    
    function getPercents() public {
        require(deposits[msg.sender].open == true);
        uint16 count = uint16((now - deposits[msg.sender].last_upd) / 86400 / deposits[msg.sender].term);
        for (uint16 i = 0; i < count; ++i)
            deposits[msg.sender].value += (deposits[msg.sender].value * deposits[msg.sender].percent / 100);
        deposits[msg.sender].last_upd = now;
    }
    
    function getPercents(address client) public {
        require(msg.sender == owner);
        require(deposits[client].open == true);
        uint16 count = uint16((now - deposits[client].last_upd) / 86400 / deposits[client].term);
        for (uint16 i = 0; i < count; ++i)
            deposits[client].value += (deposits[client].value * deposits[client].percent / 100);
        deposits[client].last_upd = now;
    }
    
    function getMoneyFromDeposit(address client) external {
        Admin admin = Admin(admin_address);
        require(!admin.checkUser(msg.sender, client));
        require(deposits[msg.sender].open == true);
        list_of_deposits.push(msg.sender);
    }
    
    function returnMoney() public payable {
        require(msg.sender == owner);
        for (uint16 i = 0; i < list_of_deposits.length; ++i) {
            getPercents(address(list_of_deposits[i]));
            tm.send(list_of_deposits[i]);
        }
        list_of_deposits = new address payable[](0);
    }
    
    function setDeposit(address user) external payable {
        Admin admin = Admin(admin_address);
        require(!admin.checkUser(msg.sender, user));
        require(deposits[msg.sender].open == true);
        getPercents();
        deposits[msg.sender].value += msg.value;
    }
    
    function askCredit(address user, uint256 value, uint8 percent, uint64 term) external {
        Admin admin = Admin(admin_address);
        require(!admin.checkUser(msg.sender, user));
        require(credits[msg.sender].value == 0);
        ask_credits[msg.sender].value = value;
        ask_credits[msg.sender].percent = percent;
        ask_credits[msg.sender].term = term;
    }
    
    function getCredit(address client, uint256 value, uint8 percent, uint64 term) public {
        require(msg.sender == owner);
        require(checkSubs(main_address, 1));
        require(ask_credits[client].value == value);
        require(ask_credits[client].percent == percent);
        require(ask_credits[client].term == term);
        credits[client].value = value;
        credits[client].percent = percent;
        credits[client].term = term;
        credits[client].last_pay = now;
        list_of_credits.push(client);
    }
    
    function checkOneCredit(address client) public {
        require(credits[client].value > 0);
        uint16 count = uint16((now - credits[client].last_pay) / 86400 / credits[client].term);
        for (uint16 j = 0; j < count; ++j)
            credits[client].value += (credits[client].value * credits[client].percent / 100);
        credits[client].last_pay = now;
    }
    
    function checkCredits() public {
        require(msg.sender == owner);
        require(checkSubs(main_address, 1));
        for (uint16 i = 0; i < list_of_credits.length; ++i)
            checkOneCredit(list_of_credits[i]);
    }
    
    function payCredit(address user) external payable {
        Admin admin = Admin(admin_address);
        require(!admin.checkUser(msg.sender, user));
        checkOneCredit(msg.sender);
        require(msg.value >= credits[msg.sender].value);
        credits[msg.sender].value = 0;
    }
}


/*
The implementation of contracts for business
and investors cannot be written within the 
framework of a training project, since we 
cannot issue securities.
This functionality can be perceived as 
a project development perspective
*/

contract Business {
    address private owner;
    address main_address;
    Transfer_money tm;
    
    constructor (address main) public {
        owner = msg.sender;
        tm = new Transfer_money();
        main_address = main;
    }
}

contract Investor {
    address private owner;
    address main_address;
    Transfer_money tm;
    
    constructor (address main) public {
        owner = msg.sender;
        tm = new Transfer_money();
        main_address = main;
    }
}