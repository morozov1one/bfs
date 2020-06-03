pragma solidity >=0.6.0 <= 0.6.8;

contract Admin {
    address private owner;

    event ConstructorInitiated(string nextStep);

    uint64[4] private prices; //цены на профили
    mapping(address => address) private users;
    mapping(address => bool) private users0;

    constructor () public {
        emit ConstructorInitiated("Вызван конструктор Admin");
        owner = msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getAddress() external view returns(address) {
        return address(this);
    }

    function setPrice(uint8 profile, uint64 price) public {
        require(msg.sender == owner);
        prices[profile] = price;
    }

    function getPrice(uint8 profile) external view returns(uint64) {
        return prices[profile];
    }

    function setUserAddress(address wallet) public {
        require(msg.sender == owner);
        users0[wallet] = true;
    }

    function setUserAddress(address wallet, address user_contract) public {
        require(msg.sender == owner);
        users[wallet] = user_contract;
    }

    function checkUser(address wallet, address user_contract) external view returns(bool) {
        return (users[wallet] == users[user_contract]);
    }

    function checkUser(address wallet) external view returns(bool) {
        return users0[wallet];
    }
}