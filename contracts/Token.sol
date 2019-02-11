pragma solidity ^0.5.2;

import "../../../openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "../../../openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "../../../openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "../../../openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../../../openzeppelin-solidity/contracts/access/roles/MinterRole.sol";
import "./MigrationAgent.sol";
import "./DateTime.sol";


/**
 * @title Token
 * @dev Burnable, Mintabble, Ownable, and Pausable
 */
contract Token is Pausable, ERC20Detailed, Ownable, ERC20Burnable, MinterRole {


    using DateTime for uint256;
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 250000000 * (10 ** uint256(DECIMALS));   
    uint256 public constant ONE_YEAR_SUPPLY = 12500000 * (10 ** uint256(DECIMALS));   
    address public migrationAgent;
    uint256 public totalMigrated;
    address public mintAgent;    

    mapping (uint => bool) public mintedYears;

    event RefundTokens(address indexed user, uint256 amount);
    event Migrate(address indexed from, address indexed to, uint256 value);
    event MintAgentSet(address indexed mintAgent);
    event MigrationAgentSet(address indexed migrationAgent);

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("AuditChain", "AUDT", DECIMALS)  {      
        _mint(msg.sender, INITIAL_SUPPLY + ONE_YEAR_SUPPLY);     
        mintedYears[now.getYear()] = true;
    }
     
     /// @dev Function to mint tokens
     /// @return A boolean that indicates if the operation was successful.
    function mint() public onlyMinter returns (bool) {

        require(mintAgent != address(0), "Mint agent address can't be 0");
        require (!mintedYears[now.getYear()], "Tokens have been already minted for this year.");

        _mint(owner(), ONE_YEAR_SUPPLY);
        mintedYears[now.getYear()] = true;

        return true;
    }

    /// @notice Set contract to which yearly tokens will be minted
    /// @param _mintAgent - address of the contract to set
    function setMintContract(address _mintAgent) external onlyOwner() {

        require(_mintAgent != address(0) , "Mint agent address can't be 0");
        mintAgent = _mintAgent;
        emit MintAgentSet(_mintAgent);
    }

    /// @notice Migrate tokens to the new token contract.
    /// @dev Required state: Operational Migration
    /// @param _value The amount of token to be migrated
    function migrate(uint256 _value) external whenNotPaused() {
        // Abort if not in Operational Migration state.   

        require(migrationAgent != address(0), "Enter migration agent address");
        
        // Validate input value.
        require(_value > 0, "Amount of tokens is required");
        require(_value <= balanceOf(msg.sender), "You entered more tokens than available");
       
        burn(balanceOf(msg.sender));
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        emit Migrate(msg.sender, migrationAgent, _value);
    }

    /// @notice Set address of migration target contract and enable migration process
    /// @param _agent The address of the MigrationAgent contract
    function setMigrationAgent(address _agent) external onlyOwner() {       

        require(migrationAgent == address(0), "Migration agent can't be 0");       
        migrationAgent = _agent;
        emit MigrationAgentSet(_agent);
    }
    
}