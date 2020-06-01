pragma solidity >=0.6.0 <= 0.6.8;

import 'https://github.com/morozov1one/bfs/blob/dev_sol/smart_contracts/Admin.sol';

contract Transfer_money {
    function send(address payable recipient) external payable {
        recipient.transfer(msg.value);
    }
}

contract Main {
    address private owner;
    address payable constant bfs_wallet = 0x0da52A47b11fFFefEf609E41FCF956b52ca9a2Ef;
    address constant admin_address = 0x4F9A5F5b62dF60Be95a92f0aD2fC0c82f5E1287F;
    
    uint64[4] private subs_days; // сколько дней подписки осталось
    uint256[4] private last_upd; // последнее обновление
    
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
        Admin admin = Admin(admin_address);
        require(admin.checkUser(msg.sender));
        owner = msg.sender;
        subs_days[0] = 0; //Обычный пользователь
        subs_days[1] = 0; //Банкир
        subs_days[2] = 0; //Предприятие
        subs_days[3] = 0; //Инвестор
        last_upd[0] = now; //Обычный пользователь
        last_upd[1] = now; //Банкир
        last_upd[2] = now; //Предприятие
        last_upd[3] = now; //Инвестор
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
    address constant admin_address = 0x4F9A5F5b62dF60Be95a92f0aD2fC0c82f5E1287F;
    address main_address;
    Transfer_money tm;
    
    struct debt {
        uint256 value; //Значение долга
        uint8 percent; //"Штрафные" проценты
        uint64 term; //За сколько дней отдать нужно
        uint256 last_pay; //Когда платил в последний раз
    }
    
    struct deposit {
        bool open;
        uint256 value;
        uint8 percent;
        uint16 term; //Раз в сколько дней начисляются проценты
        uint256 last_upd; //Когда последний раз начислялись проценты
    }
    
    address[] private list_of_credits;
    mapping(address => deposit) private deposits;
    mapping(address => debt) private credits;
    mapping(address => debt) private ask_credits;
    
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
    
    function setDeposit(address user) external payable {
        Admin admin = Admin(admin_address);
        require(admin.checkUser(msg.sender, user));
        require(deposits[msg.sender].open == true);
        getPercents();
        deposits[msg.sender].value += msg.value;
    }
    
    function askCredit(address user, uint256 value, uint8 percent, uint64 term) external {
        Admin admin = Admin(admin_address);
        require(admin.checkUser(msg.sender, user));
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
        require(admin.checkUser(msg.sender, user));
        checkOneCredit(msg.sender);
        require(msg.value >= credits[msg.sender].value);
        credits[msg.sender].value = 0;
    }
}


/*
Реализацию контрактов для бизнеса и инвесторов 
невозможно написать в рамках учебного проекта,
так как мы не можем сделать выпуск ценных бумаг.

Этот функционал можно воспринимать как
перспективы развития проекта.
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