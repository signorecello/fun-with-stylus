// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Ballot {
    address public admin;
    mapping(address => bool) public registered;
    mapping(address => bytes32) public commits;
    mapping(address => bool) public revealed;
    uint256 public votesA;
    uint256 public votesB;
    uint256 public phase; // 0=setup, 1=commit, 2=reveal, 3=done

    // admin registers a voter (phase 0 only).
    function register(address voter) external {
        // First call sets the admin
        if (admin == address(0)) {
            admin = msg.sender;
        } else {
            // in Solidity you'd normally use a modifier like "onlyAdmin"
            // keeping it inline here so both versions read the same way
            require(msg.sender == admin, "only admin");
        }

        require(phase == 0, "not setup phase");
        registered[voter] = true;
    }

    // admin advances the phase: 0->1->2->3.
    function advancePhase() external {
        require(msg.sender == admin, "only admin");
        require(phase < 3, "already done");
        phase++;
    }

    // voter submits a commit hash (phase 1 only).
    // hash should be keccak256(abi.encode(vote, salt)) computed off-chain
    function commit(bytes32 hash) external {
        require(phase == 1, "not commit phase");
        require(registered[msg.sender], "not registered");
        require(commits[msg.sender] == bytes32(0), "already committed");

        commits[msg.sender] = hash;
    }

    // voter reveals their vote and salt (phase 2 only).
    // vote=0 for candidate A, vote=1 for candidate B.
    function reveal(uint256 vote, bytes32 salt) external {
        require(phase == 2, "not reveal phase");
        require(registered[msg.sender], "not registered");
        require(!revealed[msg.sender], "already revealed");

        bytes32 expected = keccak256(abi.encode(vote, salt));
        require(expected == commits[msg.sender], "hash mismatch");

        revealed[msg.sender] = true;

        if (vote == 0) {
            votesA++;
        } else {
            votesB++;
        }
    }

    // returns the current phase.
    function getPhase() external view returns (uint256) {
        return phase;
    }

    // returns (votes_a, votes_b).
    function getVotes() external view returns (uint256, uint256) {
        return (votesA, votesB);
    }
}
