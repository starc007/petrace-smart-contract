// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

// import "../interfaces/IBlast.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract PetRace is Ownable2Step, ReentrancyGuard {
    uint256 public constant MAX_PETS = 10000;
    uint256 public constant BASE_PRICE = 0.001 ether;
    uint256 public constant MAX_LEVEL = 100;
    uint256 public constant MAX_PETS_PER_GAME = 10;

    address public platformFeeAddress;
    uint256 public platformFee = 0.1 * 1 ether; // 10% of the entry fees
    uint256 public constant FIRST_WINNER_PRIZE = 0.5 * 1 ether; // 50% of the entry fees
    uint256 public constant SECOND_WINNER_PRIZE = 0.3 * 1 ether; // 30% of the entry fees
    uint256 public constant THIRD_WINNER_PRIZE = 0.2 * 1 ether; // 20% of the entry fees

    address blastAddress = 0x4300000000000000000000000000000000000002;

    struct PetMaxAttributes {
        uint256 speed;
        uint256 stamina;
        uint256 strength;
        uint256 agility;
        uint256 intelligence;
        uint256 luck;
    }

    /**
     * @dev Pet Attributes Fees
     */
    struct PetAttributesFees {
        uint256 speed;
        uint256 stamina;
        uint256 strength;
        uint256 agility;
        uint256 intelligence;
        uint256 luck;
    }

    /**
     * @dev Pet struct
     */
    struct Pet {
        uint256 id;
        string name;
        uint256 speed;
        uint256 stamina;
        uint256 strength;
        uint256 agility;
        uint256 intelligence;
        uint256 luck;
        uint256 level;
        uint256 experience;
        uint256 wins;
        uint256 losses;
        uint256 draws;
        uint256 raceCount;
        uint256 basePrice;
        address owner;
    }

    /**
     * @dev Game struct
     */
    struct Game {
        uint256 id;
        uint256[] pets;
        uint256[] winners; // Top 3 pets
        uint256 winningPrize; // 90% of the entry fees
        uint256 entryFee;
        uint256 startTime;
        uint256 endTime;
        uint256 raceDistance;
        bool isFinished;
    }

    Pet[] public pets;
    Game[] public games;
    PetAttributesFees public petAttributesFees;
    PetMaxAttributes public petMaxAttributes;

    event PetCreated(uint256 id, string name);
    event GameCreated(uint256 id, uint256 startTime, uint256 endTime);
    event JoinGame(uint256 gameId, uint256 petId);

    constructor(address _platformFeeAddress) {
        platformFeeAddress = _platformFeeAddress;
        petAttributesFees = PetAttributesFees({
            speed: 0.001 ether,
            stamina: 0.001 ether,
            strength: 0.001 ether,
            agility: 0.001 ether,
            intelligence: 0.001 ether,
            luck: 0.001 ether
        });

        petMaxAttributes = PetMaxAttributes({
            speed: 100,
            stamina: 100,
            strength: 100,
            agility: 100,
            intelligence: 100,
            luck: 100
        });

        // IBlast(blastAddress).configureClaimableGas();
        // IBlast(blastAddress).configureClaimableYield();
    }

    modifier onlyPlatformFeeAddress() {
        require(
            msg.sender == platformFeeAddress,
            "Caller is not the platform fee address"
        );
        _;
    }

    modifier isPetOwner(uint256 _petId) {
        require(
            pets[_petId].owner == msg.sender,
            "You are not the owner of the pet"
        );
        _;
    }

    /**
     * @dev Set the platform fee address
     * @param _platformFeeAddress The address of the platform fee
     */
    function setPlatformFeeAddress(
        address _platformFeeAddress
    ) external onlyOwner {
        platformFeeAddress = _platformFeeAddress;
    }

    /**
     * @dev Set the platform fee
     * @param _platformFee The platform fee
     */
    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }

    /**
     * @dev Set the blast address
     * @param _blastAddress The address of the blast contract
     */

    function setBlastAddress(address _blastAddress) external onlyOwner {
        blastAddress = _blastAddress;
    }

    /**
     * @dev Set Pet Attributes Fees
     * @param _speed The speed fee
     * @param _stamina The stamina fee
     * @param _strength The strength fee
     * @param _agility The agility fee
     * @param _intelligence The intelligence fee
     * @param _luck The luck fee
     */
    function setPetAttributesFees(
        uint256 _speed,
        uint256 _stamina,
        uint256 _strength,
        uint256 _agility,
        uint256 _intelligence,
        uint256 _luck
    ) external onlyOwner {
        petAttributesFees = PetAttributesFees({
            speed: _speed,
            stamina: _stamina,
            strength: _strength,
            agility: _agility,
            intelligence: _intelligence,
            luck: _luck
        });
    }

    /**
     * @dev Set Pet Max Attributes
     * @param _speed The max speed
     * @param _stamina The max stamina
     * @param _strength The max strength
     * @param _agility The max agility
     * @param _intelligence The max intelligence
     * @param _luck The max luck
     */
    function setPetMaxAttributes(
        uint256 _speed,
        uint256 _stamina,
        uint256 _strength,
        uint256 _agility,
        uint256 _intelligence,
        uint256 _luck
    ) external onlyOwner {
        petMaxAttributes = PetMaxAttributes({
            speed: _speed,
            stamina: _stamina,
            strength: _strength,
            agility: _agility,
            intelligence: _intelligence,
            luck: _luck
        });
    }

    /**
     * @dev Create a new pet
     * @param _name The name of the pet
     */
    function createPet(string memory _name) external payable nonReentrant {
        uint256 id = pets.length;
        pets.push(
            Pet({
                id: id,
                name: _name,
                speed: 1,
                stamina: 1,
                strength: 1,
                agility: 1,
                intelligence: 1,
                luck: 1,
                level: 1,
                experience: 0,
                wins: 0,
                losses: 0,
                draws: 0,
                raceCount: 0,
                basePrice: BASE_PRICE,
                owner: msg.sender
            })
        );
        emit PetCreated(id, _name);
    }

    /**
     * @dev Create a new game, Only the owner can create a game
     * @param _startTime The start time of the game
     * @param _endTime The end time of the game
     * @param _entryFee The entry fee of the game
     * @param _raceDistance The distance
     */
    function createGame(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _entryFee,
        uint256 _raceDistance
    ) external onlyOwner {
        uint256 id = games.length;
        games.push(
            Game({
                id: id,
                pets: new uint256[](0),
                winners: new uint256[](0),
                winningPrize: 0,
                entryFee: _entryFee,
                startTime: _startTime,
                endTime: _endTime,
                raceDistance: _raceDistance,
                isFinished: false
            })
        );
        emit GameCreated(id, _startTime, _endTime);
    }

    /**
     * @dev Join a game
     * @param _gameId The id of the game
     * @param _petId The id of the pet
     */
    function joinGame(
        uint256 _gameId,
        uint256 _petId
    ) external payable nonReentrant {
        require(_gameId < games.length, "Invalid game id");
        require(_petId < pets.length, "Invalid pet id");

        require(
            pets[_petId].owner == msg.sender,
            "You are not the owner of the pet"
        );

        require(
            games[_gameId].pets.length <= MAX_PETS_PER_GAME,
            "Game is full"
        );

        require(games[_gameId].entryFee <= msg.value, "Insufficient funds");

        require(games[_gameId].isFinished == false, "Game is finished");

        require(
            block.timestamp < games[_gameId].startTime - 300, // 5 minutes before the game starts
            "You can't join the game, it's too late"
        );

        games[_gameId].pets.push(_petId);
        emit JoinGame(_gameId, _petId);
    }

    /**
     * @dev Get a Game
     * @param _gameId The id of the game
     */
    function getGame(uint256 _gameId) external view returns (Game memory) {
        require(_gameId < games.length, "Invalid game id");
        return games[_gameId];
    }

    /**
     * @dev Get all pets of a user
     * @param _owner The owner of the pets
     */
    function getMyPets(address _owner) external view returns (Pet[] memory) {
        Pet[] memory myPets = new Pet[](pets.length);
        uint256 count = 0;
        for (uint256 i = 0; i < pets.length; i++) {
            if (pets[i].owner == _owner) {
                myPets[count] = pets[i];
                count++;
            }
        }
        return myPets;
    }

    /**
     * @dev Get all Unfinished games
     */
    function getUnfinishedGames() external view returns (Game[] memory) {
        Game[] memory unfinishedGames = new Game[](games.length);
        uint256 count = 0;
        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].isFinished == false) {
                unfinishedGames[count] = games[i];
                count++;
            }
        }
        return unfinishedGames;
    }

    /**
     * @dev Get all Finished games
     */
    function getFinishedGames() external view returns (Game[] memory) {
        Game[] memory finishedGames = new Game[](games.length);
        uint256 count = 0;
        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].isFinished == true) {
                finishedGames[count] = games[i];
                count++;
            }
        }
        return finishedGames;
    }

    /**
     * @dev distribute the prize
     * @param _gameId The id of the game
     */
    function distributePrize(uint256 _gameId) external onlyOwner {
        require(_gameId < games.length, "Invalid game id");
        require(games[_gameId].isFinished == true, "Game is not finished");

        // uint256 prize = games[_gameId].winningPrize;
        uint256 prize = games[_gameId].entryFee * games[_gameId].pets.length;
        uint256 _platformFee = (prize - prize * platformFee) / 1 ether;

        uint _winningPrize = games[_gameId].winningPrize;

        (bool sentPlatform, ) = payable(platformFeeAddress).call{
            value: _platformFee
        }("");
        require(sentPlatform, "Failed to transfer the platform fee");

        for (uint256 i = 0; i < games[_gameId].winners.length; i++) {
            uint256 petId = games[_gameId].winners[i];
            uint256 winnerPrize = 0;
            if (i == 0) {
                winnerPrize = (_winningPrize * FIRST_WINNER_PRIZE) / 1 ether;
            } else if (i == 1) {
                winnerPrize = (_winningPrize * SECOND_WINNER_PRIZE) / 1 ether;
            } else if (i == 2) {
                winnerPrize = (_winningPrize * THIRD_WINNER_PRIZE) / 1 ether;
            }

            (bool sent, ) = payable(pets[petId].owner).call{value: winnerPrize}(
                ""
            );
            require(sent, "Failed to transfer the prize");
        }
    }

    /**
     * @dev Finish a game
     * @param _gameId The id of the game
     * @param _winners The ids of the winners
     */
    function finishGame(
        uint256 _gameId,
        uint256[] memory _winners
    ) external onlyOwner {
        require(_gameId < games.length, "Invalid game id");
        require(games[_gameId].isFinished == false, "Game is already finished");

        games[_gameId].winners = _winners;
        games[_gameId].isFinished = true;

        uint256 prize = games[_gameId].entryFee * games[_gameId].pets.length;
        games[_gameId].winningPrize = prize - platformFee;
    }

    /**
     * @dev Upgrade a pet
     * @param _petId The id of the pet
     * @param _speed The speed of the pet
     */
    function upgradePetSpees(
        uint256 _petId,
        uint256 _speed
    ) external payable isPetOwner(_petId) nonReentrant {
        require(_speed <= petMaxAttributes.speed, "Invalid speed");

        uint256 _speedFees = petAttributesFees.speed * _speed;
        require(msg.value >= _speedFees, "Insufficient funds");
        pets[_petId].speed = _speed;
    }

    /**
     * @dev Upgrade a pet
     * @param _petId The id of the pet
     * @param _stamina The stamina of the pet
     */
    function upgradePetStamina(
        uint256 _petId,
        uint256 _stamina
    ) external payable isPetOwner(_petId) nonReentrant {
        require(_stamina <= petMaxAttributes.stamina, "Invalid stamina");

        uint256 _staminaFees = petAttributesFees.stamina * _stamina;
        require(msg.value >= _staminaFees, "Insufficient funds");
        pets[_petId].stamina = _stamina;
    }

    /**
     * @dev Upgrade a pet
     * @param _petId The id of the pet
     * @param _strength The strength of the pet
     */

    function upgradePetStrength(
        uint256 _petId,
        uint256 _strength
    ) external payable isPetOwner(_petId) nonReentrant {
        require(_strength <= petMaxAttributes.strength, "Invalid strength");

        uint256 _strengthFees = petAttributesFees.strength * _strength;
        require(msg.value >= _strengthFees, "Insufficient funds");
        pets[_petId].strength = _strength;
    }

    /**
     * @dev Upgrade a pet
     * @param _petId The id of the pet
     * @param _agility The agility of the pet
     */
    function upgradePetAgility(
        uint256 _petId,
        uint256 _agility
    ) external payable isPetOwner(_petId) nonReentrant {
        require(_agility <= petMaxAttributes.agility, "Invalid agility");

        uint256 _agilityFees = petAttributesFees.agility * _agility;
        require(msg.value >= _agilityFees, "Insufficient funds");
        pets[_petId].agility = _agility;
    }

    /**
     * @dev Upgrade a pet
     * @param _petId The id of the pet
     * @param _intelligence The intelligence of the pet
     */
    function upgradePetIntelligence(
        uint256 _petId,
        uint256 _intelligence
    ) external payable isPetOwner(_petId) nonReentrant {
        require(
            _intelligence <= petMaxAttributes.intelligence,
            "Invalid intelligence"
        );

        uint256 _intelligenceFees = petAttributesFees.intelligence *
            _intelligence;
        require(msg.value >= _intelligenceFees, "Insufficient funds");
        pets[_petId].intelligence = _intelligence;
    }

    /**
     * @dev Upgrade a pet
     * @param _petId The id of the pet
     * @param _luck The luck of the pet
     */
    function upgradePetLuck(
        uint256 _petId,
        uint256 _luck
    ) external payable isPetOwner(_petId) nonReentrant {
        require(_luck <= petMaxAttributes.luck, "Invalid luck");

        uint256 _luckFees = petAttributesFees.luck * _luck;
        require(msg.value >= _luckFees, "Insufficient funds");
        pets[_petId].luck = _luck;
    }

    // /**
    //  * @dev Claim the yield & gas
    //  */
    // function claimYieldAndGas() external onlyPlatformFeeAddress {
    //     IBlast(blastAddress).claimAllYield(address(this), msg.sender);
    //     IBlast(blastAddress).claimAllGas(address(this), msg.sender);
    // }
}
