// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
// import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

contract GrowthUP is Governor, GovernorVotes {
    // contract description
    bytes32 private constant MODULE_TYPE = bytes32("VoteERC20");
    uint256 private constant VERSION = 1;

    // DAO description
    address private _gavarnanceToken; // ガバナンストークン（投票が可能なトークン）
    uint8 private _voteUnit; // 1token = 1投票
    address private constant PRE_PROPOSE_ADDRESS =
        0x2B38BA2E0C8251D02b61C4DFBEe161dbb6AE3e66; // preProposalができるアドレス

    // preProposal description
    uint256 private _prePrposalIndex = 0; // preProposal index
    uint256 private _preProposalVotingDelay; // 投票AIの投票開始までの時間
    uint256 private _prePrpposalVotingPeriod; // 投票AIの投票開始から終了までの時間
    uint256 private _preProposalThreshold; // AI投票に必要な投票数。ex 10人の投票AIが存在するとき10が閾値

    // proposal description
    // preProposal description
    uint256 private _proposalIndex = 0; // proposal index
    uint256 private _proposalVotingDelay; // プロジェクト参加企業の参加表明開始までの時間
    uint256 private _prpposalVotingPeriod; // プロジェクト参加企業の参加表明開始から終了までの時間
    uint256 private _proposalThreshold; // プロジェクト開始と終了に合意が必要な人数。ex 4社にプロジェクト提案を行う場合、４社が参加表明することでプロジェクトが開始状態になる。また、プロジェクトを終了させるときの合意人数となる。
    uint8 private _projectFinished; // プロジェクトが終了したフラグ 終了した場合TRUEがたつ

    /**
     * preProposal
     * AIが提案と投票を行う。投票が可決されたものが、prposalに昇格する
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
     * プロジェクトの参加を募集する企業に向けた提案。
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
        // TODO: プロジェクトオファーする会社をlistで登録できるようにする
    }

    /// @dev preProposal index => Proposal
    mapping(uint256 => PreProposal) public preProposals;

    /// @dev proposal index => Proposal
    mapping(uint256 => Proposal) public proposals;

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        IVotes _token,
        TimelockController _timelock
    ) Governor("GrowthUP") GovernorVotes(_token) {}

    /**
     * new propose
     * prePrposalとproposalの発行
     *
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256 _proposalId) {
        // proposalの作成
        _proposalId = super.propose(targets, values, calldatas, description);

        if (msg.sender == PRE_PROPOSE_ADDRESS) {
            // AI投稿用アドレス
            preProposals[_prePrposalIndex] = PreProposal({
                proposalId: _proposalId,
                proposer: _msgSender(),
                targets: targets,
                values: values,
                signatures: new string[](targets.length),
                calldatas: calldatas,
                startBlock: proposalSnapshot(_proposalId),
                endBlock: proposalDeadline(_proposalId),
                description: description
            });
            _prePrposalIndex +=1;
        } else {
            proposals[_proposalIndex] = Proposal({
                proposalId: _proposalId,
                proposer: _msgSender(),
                targets: targets,
                values: values,
                signatures: new string[](targets.length),
                calldatas: calldatas,
                startBlock: proposalSnapshot(_proposalId),
                endBlock: proposalDeadline(_proposalId),
                description: description
            });
            _proposalIndex +=1;
        }
    }

    /**
     * 投票をUIからリクエストを行う関数
     * support 0:承認 1:否決 2:棄権
     */
    function castVote(uint256 proposalId, uint8 support) public override returns (uint256) {
        address voter = msg.sender;
        super.castVote(proposalId, support);
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
        countVoteTest += 1;
    }

    /**
     * 全てのpreProposal取得
     */
    function getAllPreProposals() external view returns (PreProposal[] memory allPreProposals)  {
        uint256 nextPreProposalIndex = _prePrposalIndex;

        allPreProposals = new PreProposal[](nextPreProposalIndex);
        for (uint256 i = 0; i < nextPreProposalIndex; i += 1) {
            allPreProposals[i] = preProposals[i];
        }
    }

    /**
     * 全てのpreProposal取得
     */
    function getAllProposals() external view returns (Proposal[] memory allProposals) {
        uint256 nextProposalIndex = _proposalIndex;

        allProposals = new Proposal[](nextProposalIndex);
        for (uint256 i = 0; i < nextProposalIndex; i += 1) {
            allProposals[i] = proposals[i];
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
    function votingDelay() public view override returns (uint256) {
        // TODO preProposalとproposalで待機時間を切り替えられるようにする
        return 0;
    }
    
    /**
     * 投票が開始されてから終了するまでのブロック数
     * 1block -> 約1s
     */
    function votingPeriod() public view override returns (uint256) {
        // TODO preProposalとproposalで待機時間を切り替えられるようにする
        return 100;
    }

    function quorum(uint256 timepoint) public view override returns (uint256) {}

    function hasVoted(
        uint256 proposalId,
        address account
    ) external view override returns (bool) {}

    function _quorumReached(
        uint256 proposalId
    ) internal view virtual override returns (bool) {}

    function _voteSucceeded(
        uint256 proposalId
    ) internal view virtual override returns (bool) {}


}