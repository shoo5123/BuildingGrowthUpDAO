// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

contract GrowthUP is Governor, GovernorVotes, GovernorVotesQuorumFraction {
    // contract description
    bytes32 private constant MODULE_TYPE = bytes32("VoteERC20");
    uint256 private constant VERSION = 1;

    // DAO description
    address private _gavarnanceToken; // ガバナンストークン（投票が可能なトークン）
    uint8 private _voteUnit; // 1token = 1投票
    address private constant PRE_PROPOSE_ADDRESS =
        0x2B38BA2E0C8251D02b61C4DFBEe161dbb6AE3e66; // preProposalができるアドレス
    uint256 constant VOTE_INIT = 0; // 投票の初期値

    uint256 private _prePrposalIndex = 0; // preProposal index
    // uint256 private _preProposalVotingDelay; // 投票AIの投票開始までの時間
    // uint256 private _prePrpposalVotingPeriod; // 投票AIの投票開始から終了までの時間
    // uint256 private _preProposalThreshold; // AI投票に必要な投票数。ex 10人の投票AIが存在するとき10が閾値

    uint256 private _projectProposalIndex = 0; // proposal index
    uint256 private _proposalVotingDelay; // プロジェクト参加企業の参加表明開始までの時間
    // uint256 private _prpposalVotingPeriod; // プロジェクト参加企業の参加表明開始から終了までの時間
    // uint256 private _proposalThreshold; // プロジェクト開始と終了に合意が必要な人数。ex 4社にプロジェクト提案を行う場合、４社が参加表明することでプロジェクトが開始状態になる。また、プロジェクトを終了させるときの合意人数となる。
    // uint8 private _projectFinished; // プロジェクトが終了したフラグ 終了した場合TRUEがたつ

    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address voter => bool) hasVoted;
    }
 
    /**
     * preProposal
     * AIが提案と投票を行う。投票が可決されたものが、prposalに昇格する
     */
    struct PreProposal {
        uint256 id;
        uint256 proposalId;
        address proposer;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        string description;
        string[] offers;
    }

    /**
     * Proposal
     * プロジェクトの参加を募集する企業に向けた提案。
     */
    struct ProjectProposal {
        uint256 id;
        uint256 proposalId;
        address proposer;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        string description;
        string[] offers;
    }

    /**
     * projectProposal
     * フロント用レスポンスインターフェース
     */
    struct ProposalResponce {
        uint id;
        string proposalId;
        string description;
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        ProposalState status;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
    }

    /// Maps
    /// @dev poposalIdからidを引けるようにする proposalId => id
    mapping(uint256 => uint256) public preProposalNoMap;
    mapping(uint256 => uint256) public projectProposalNoMap;
    /// @dev preProposal index => Proposal
    mapping(uint256 => PreProposal) public preProposals;
    mapping(uint256 => ProjectProposal) public projectProposals;
    /// @dev proposalVotes poposalIdと投票結果のmap
    mapping(uint256 proposalId => ProposalVote) public proposalVotes;

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        IVotes _token
    ) Governor("GrowthUP") GovernorVotes(_token) GovernorVotesQuorumFraction(0){}

    /**
     * new propose
     * prePrposalとproposalの発行
     */
    function proposeWithOffers(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description,
        string[] memory offers
    ) public returns (uint256 _proposalId) {
        _proposalId = propose(targets, values, calldatas, description);

        if (msg.sender == PRE_PROPOSE_ADDRESS) {
            // AI投稿用アドレスのとき
            // data set
            PreProposal storage preProposal = preProposals[_prePrposalIndex];
            preProposal.id = _prePrposalIndex;
            preProposal.proposalId = _proposalId;
            preProposal.proposer = msg.sender;
            preProposal.targets = targets;
            preProposal.values = values;
            preProposal.signatures = new string[](targets.length);
            preProposal.calldatas = calldatas;
            preProposal.startBlock = proposalSnapshot(_proposalId);
            preProposal.endBlock = proposalDeadline(_proposalId);
            preProposal.description = description;
            preProposal.offers = offers;

            preProposalNoMap[_proposalId] = _prePrposalIndex;
            _prePrposalIndex += 1;
        } else {
            // data set
            ProjectProposal storage projectProposal = projectProposals[_projectProposalIndex];
            projectProposal.id = _projectProposalIndex;
            projectProposal.proposalId = _proposalId;
            projectProposal.proposer = msg.sender;
            projectProposal.targets = targets;
            projectProposal.values = values;
            projectProposal.signatures = new string[](targets.length);
            projectProposal.calldatas = calldatas;
            projectProposal.startBlock = proposalSnapshot(_proposalId);
            projectProposal.endBlock = proposalDeadline(_proposalId);
            projectProposal.description = description;
            projectProposal.offers = offers;

            projectProposalNoMap[_proposalId] = _projectProposalIndex;
            _projectProposalIndex += 1;
        }
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256 _proposalId) {
        // proposalの作成
        // HACK: このメソッドはintarnalにしたいけど、interfaceに縛られてるので変更したい
        _proposalId = super.propose(targets, values, calldatas, description);
    }

    /**
     * 投票をUIからリクエストを行う関数
     * support 0:承認 1:否決 2:棄権
     */
    function castVote(
        uint256 proposalId,
        uint8 support
    ) public override returns (uint256) {
        super.castVote(proposalId, support);
        address _account = msg.sender;
    }

    /**
     * 投票をUIからリクエストを行う関数
     * support 0:承認 1:否決 2:棄権
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal override {
       
        //　重複投票チェック
        if (proposalVotes[proposalId].hasVoted[account]) {
            revert GovernorAlreadyCastVote(account);
        }
        
        // proposalIdがどちらかのpreproposal/projectproposalに登録されている時
        if (preProposalNoMap[proposalId] >= 1 || projectProposalNoMap[proposalId] >= 1) {
            if (support == 0) proposalVotes[proposalId].forVotes += 1;
            else if (support == 1) proposalVotes[proposalId].againstVotes += 1;
            else if (support == 2) proposalVotes[proposalId].abstainVotes += 1;
            proposalVotes[proposalId].hasVoted[account] = true;
        }
    }

    /**
     * 全てのpreProposal取得
     */
    function getAllPreProposals() external view returns (ProposalResponce[] memory proposalResponce){

        proposalResponce = new ProposalResponce[](_prePrposalIndex);
        
        for (uint256 i = 0; i < _prePrposalIndex; i += 1) {
            proposalResponce[i].id = i;
            proposalResponce[i].proposalId = Strings.toString(preProposals[i].proposalId);
            proposalResponce[i].description = preProposals[i].description;
            proposalResponce[i].proposer = preProposals[i].proposer;
            proposalResponce[i].targets = preProposals[i].targets;
            proposalResponce[i].values = preProposals[i].values;
            proposalResponce[i].startBlock = preProposals[i].startBlock;
            proposalResponce[i].endBlock = preProposals[i].endBlock;
            proposalResponce[i].status = state(preProposals[i].proposalId);
            proposalResponce[i].calldatas = preProposals[i].calldatas;
        }
    }

    /**
     * 全てのpreProposal取得
     */
    function getAllProjectProposals()
        external
        view
        returns (ProposalResponce[] memory proposalResponce)
    {
        proposalResponce = new ProposalResponce[](_projectProposalIndex);

        for (uint256 i = 0; i < _projectProposalIndex; i += 1) {
            proposalResponce[i].id = i;
            proposalResponce[i].proposalId = Strings.toString(projectProposals[i].proposalId);
            proposalResponce[i].description = projectProposals[i].description;
            proposalResponce[i].proposer = projectProposals[i].proposer;
            proposalResponce[i].targets = projectProposals[i].targets;
            proposalResponce[i].values = projectProposals[i].values;
            proposalResponce[i].startBlock = projectProposals[i].startBlock;
            proposalResponce[i].endBlock = projectProposals[i].endBlock;
            proposalResponce[i].status = state(projectProposals[i].proposalId);
            proposalResponce[i].calldatas = projectProposals[i].calldatas;
        }
    }

    // contract type
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    // contract version
    function contractVersion() public pure returns (uint8) {
        return uint8(VERSION);
    }

    function COUNTING_MODE() external view override returns (string memory) {}

    /**
     * 投票が開始までの待機ブロック数
     */
    function votingDelay() public pure override returns (uint256) {
        // TODO preProposalとproposalで待機時間を切り替えられるようにする
        return 0;
    }

    /**
     * 投票が開始されてから終了するまでのブロック数
     * 1block -> 約1s
     */
    function votingPeriod() public pure override returns (uint256) {
        // TODO preProposalとproposalで待機時間を切り替えられるようにする
        return 100;
    }

    function quorum(uint256 timepoint) public view override(Governor, GovernorVotesQuorumFraction) returns (uint256) {}

    function hasVoted(
        uint256 proposalId,
        address account
    ) external view override returns (bool) {
        return proposalVotes[proposalId].hasVoted[account];
    }

    function _quorumReached(
        uint256 proposalId
    ) internal view virtual override returns (bool) {
        // todo proposeでOfferになったアドレスの投票が全て終わったらtrue
        return true;
    }

    function _voteSucceeded(
        uint256 proposalId
    ) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = proposalVotes[proposalId];

        return proposalVote.forVotes > proposalVote.againstVotes;
    }
}