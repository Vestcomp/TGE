pragma solidity ^0.5.2;


import "../../../openzeppelin-solidity/contracts/ownership/Ownable.sol";

/// @title Locked
/// @dev Smart contract to enable locking and unlocking of token holders. 
contract Locked is Ownable {

    mapping (address => bool) public lockedList;

    event AddedLock(address user);
    event RemovedLock(address user);


    /// @dev terminate transaction if any of the participants is locked
    /// @param _from - user initiating process
    /// @param _to  - user involved in process
    modifier isNotLocked(address _from, address _to) {

        if (_from != owner()) {  // allow contract owner on sending tokens even if recipient is locked
            require(!lockedList[_from], "User is locked");
            require(!lockedList[_to], "User is locked");
        }
        _;
    }

    /// @dev check if user has been locked
    /// @param _user - usr to check
    /// @return true or false
    function isLocked(address _user) public view returns (bool) {
        return lockedList[_user];
    }
    
    /// @dev add user to lock
    /// @param _user to lock
    function addLock (address _user) public onlyOwner {
        lockedList[_user] = true;
        emit AddedLock(_user);
    }

    /// @dev unlock user
    /// @param _user - user to unlock
    function removeLock (address _user) public onlyOwner {
        lockedList[_user] = false;
        emit RemovedLock(_user);
    }

}