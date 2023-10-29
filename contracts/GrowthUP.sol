// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC20Vote.sol";

contract GrowthUP is ERC20Vote {
    
    // contract description
    bytes32 private constant MODULE_TYPE = bytes32("VoteERC20");
    uint256 private constant VERSION = 1;

    // DAO definition
    address private _gavarnanceToken; // ガバナンストークン
    uint256 private _votingDelay;  // 投票開始までの時間
    uint256 private _votingPeriod; // 投票開始から終了までの時間

    /**
     * preProposal
     * AIが提案と投票を行う。投票が可決されたものが、prposalに昇格する
     * @dev proposalIdはpreProposalとproposalで同じものを使う
     */
    struct PreProposal {
        uint256 proposalId;
        address proposer;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        string description;
    }

    /**
     * Proposal
     * AIによるproposal
     * @dev proposalIdはpreProposalとproposalで同じものを使う
     */
    struct Proposal {
        uint256 proposalId;
        address proposer;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        string description;
    }

    /// @dev proposal index => Proposal
    mapping(uint256 => PreProposal) public preProposals;

    /// @dev proposal index => Proposal
    mapping(uint256 => Proposal) public proposals;

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _token, // gavernance token
        uint256 _initialVotingDelay,
        uint256 _initialVotingPeriod
    )
        ERC20Vote(
            _defaultAdmin,
            _name,
            _symbol
        )
    {
        _gavarnanceToken = _token;
        _votingDelay = _initialVotingDelay;
        _votingPeriod = _initialVotingPeriod;

    }

    /**
     * new preProposal
     * AIによって提案された提案内容をこのメソッドを使ってDAOに連携する
     */
    function preProposal() external pure returns (uint8) {
        // pre-proposalの作成
        // proposalIdのインクリメント
        return 1;
    }

    /**
     * new proposal
     * AIによって可決された提案内容をこのメソッドを使ってDAOに連携する
     * 
     */
    function proposal() external pure returns (uint8) {
        // proposalの作成
        // proposalIdのインクリメント
        return 1;
    }

    /**
     * preProposalの可決
     * AIによって判断された可否決をこのメソッドを使って投票する
     * 
     */
    function votePreProposal() external pure returns (uint8) {
        // vote PreProposal
        // 投票時間前になっていないかチェック
        // 投票時間を過ぎていないかチェック
        // 投票をできるトークン数をもっているかチェック 1token 1投票数
        return 1;

    }

    /**
     * preProposalの可決
     * AIによって可決された提案は、proposalに昇格する
     * 
     */
    function voteProposal() external pure returns (uint8) {
        // vote proposal
        // 投票時間前になっていないかチェック
        // 投票時間を過ぎていないかチェック
        // 投票をできるトークン数をもっているかチェック 1token 1投票数
        return 1;
    }

    /**
     * 特定のpreProposal情報の取得
     */
    function getPreProposal(uint256 proposalId) external pure returns (uint256) {
        // proposalIdを指定してpreProposalの返却
        return proposalId;
    }

    /**
     * 全てのpreProposal情報の取得
     */
    function getAllPreProposals() external pure returns (uint8) {
        return 1;
    }
    
    /**
     * 特定のproposal情報の取得
     */
    function getProposal(uint256 proposalId) external pure returns (uint256) {
        return proposalId;
    }

    /**
     * 全てのpreProposal情報の取得
     */
    function getAllProposals() external pure returns (uint8) {
        return 1;
    }

    // contract type
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }
    
    // contract version
    function contractVersion() public pure returns (uint8) {
        return uint8(VERSION);
    }
}