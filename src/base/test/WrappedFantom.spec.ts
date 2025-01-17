import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { expect } from "chai";
import { BigNumberish } from "ethers";
import { ethers } from "hardhat";
import {
  MockERC677Receiver,
  MockFaultyReceiver,
  WrappedFantomV10,
} from "../typechain";
import {
  UniswapVersion,
  expandTo18Decimals,
  getDomainSeparator,
  toAbiEncoded,
} from "../scripts/utilities";

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const chainId = 31337;

const WITHDRAW_SIGHASH = "2e1a7d4d";
const WITHDRAW_TO_SIGHASH = "205c2878";
const WITHDRAW_FROM_SIGHASH = "9555a942";
const WALLET_AMOUNT = expandTo18Decimals(11);
const ALICE_AMOUNT = expandTo18Decimals(222);
const BOBBY_AMOUNT = expandTo18Decimals(3333);
const CAROL_AMOUNT = expandTo18Decimals(4444);
const DEREX_AMOUNT = expandTo18Decimals(55555);
const FEETO_AMOUNT = expandTo18Decimals(0);
const NEW_ROOT =
  "0xd4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77";
const EMPTY_ROOT = ethers.ZeroHash;

interface MerkleProof {
  [index: string]: {
    Address: string;
    Balance: BigNumberish;
    Proof: string[];
  };
}

describe("WrappedFantomV10", function () {
  let wftm: WrappedFantomV10;
  let mockReceiver: MockERC677Receiver;
  let mockFaultyReceiver: MockFaultyReceiver;
  let wallet: HardhatEthersSigner;
  let alice: HardhatEthersSigner;
  let bobby: HardhatEthersSigner;
  let carol: HardhatEthersSigner;
  let derex: HardhatEthersSigner;
  let feeTo: HardhatEthersSigner;
  let flashloanRoot: string;
  let userProof: MerkleProof;
  const name = "Wrapped Fantom";
  const symbol = "wFTM";
  async function mkRoot() {
    [wallet, alice, bobby, carol, derex, feeTo] = await ethers.getSigners();
    const arrayProof: MerkleProof = {
      wallet: {
        Address: wallet.address,
        Balance: WALLET_AMOUNT,
        Proof: [],
      },
      alice: {
        Address: alice.address,
        Balance: ALICE_AMOUNT,
        Proof: [],
      },
      bobby: {
        Address: bobby.address,
        Balance: BOBBY_AMOUNT,
        Proof: [],
      },
      carol: {
        Address: carol.address,
        Balance: CAROL_AMOUNT,
        Proof: [],
      },
      derex: {
        Address: derex.address,
        Balance: DEREX_AMOUNT,
        Proof: [],
      },
      feeTo: {
        Address: feeTo.address,
        Balance: FEETO_AMOUNT,
        Proof: [],
      },
    };
    const values = [
      [arrayProof.wallet.Address, arrayProof.wallet.Balance],
      [arrayProof.alice.Address, arrayProof.alice.Balance],
      [arrayProof.bobby.Address, arrayProof.bobby.Balance],
      [arrayProof.carol.Address, arrayProof.carol.Balance],
      [arrayProof.derex.Address, arrayProof.derex.Balance],
      [arrayProof.feeTo.Address, arrayProof.feeTo.Balance],
    ];
    const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
    for (const [i, v] of tree.entries()) {
      if (v[0] === arrayProof.wallet.Address) {
        arrayProof.wallet.Proof = tree.getProof(i);
      }
      if (v[0] === arrayProof.alice.Address) {
        arrayProof.alice.Proof = tree.getProof(i);
      }
      if (v[0] === arrayProof.bobby.Address) {
        arrayProof.bobby.Proof = tree.getProof(i);
      }
      if (v[0] === arrayProof.carol.Address) {
        arrayProof.carol.Proof = tree.getProof(i);
      }
      if (v[0] === arrayProof.derex.Address) {
        arrayProof.derex.Proof = tree.getProof(i);
      }
      if (v[0] === arrayProof.feeTo.Address) {
        arrayProof.feeTo.Proof = tree.getProof(i);
      }
    }
    const ROOT = tree.root;
    return { ROOT, arrayProof };
  }

  async function fixture() {
    const wftmFactory = await ethers.getContractFactory("WrappedFantomV10");
    const [wallet, alice, bobby, carol, derex, feeTo] =
      await ethers.getSigners();
    const { ROOT } = await loadFixture(mkRoot);
    wftm = await wftmFactory.deploy(ROOT);
    const mockERC667Factory =
      await ethers.getContractFactory("MockERC677Receiver");
    mockReceiver = await mockERC667Factory.deploy();
    const mockFaultyFactory =
      await ethers.getContractFactory("MockFaultyReceiver");
    mockFaultyReceiver = await mockFaultyFactory.deploy();
    return {
      wftm,
      mockReceiver,
      mockFaultyReceiver,
      wallet,
      alice,
      bobby,
      carol,
      derex,
      feeTo,
    };
  }

  before(async () => {
    const wftmFactory = await ethers.getContractFactory("WrappedFantomV10");
    [wallet, alice, bobby, carol, derex, feeTo] = await ethers.getSigners();
    const { ROOT, arrayProof } = await loadFixture(mkRoot);
    wftm = await wftmFactory.deploy(ROOT);
    const mockERC667Factory =
      await ethers.getContractFactory("MockERC677Receiver");
    mockReceiver = await mockERC667Factory.deploy();
    const mockFaultyFactory =
      await ethers.getContractFactory("MockFaultyReceiver");
    mockFaultyReceiver = await mockFaultyFactory.deploy();
    flashloanRoot = ROOT;
    userProof = arrayProof;
  });

  describe("deployment", function () {
    it("has a correct name", async function () {
      const { wftm } = await loadFixture(fixture);
      expect(await wftm.name()).to.equal(name);
    });
    it("has a correct symbol", async function () {
      const { wftm } = await loadFixture(fixture);
      expect(await wftm.symbol()).to.equal(symbol);
    });
    it("has 18 decimals", async function () {
      const { wftm } = await loadFixture(fixture);
      expect(await wftm.decimals()).to.equal(18);
    });
    it("has correct domain separator", async function () {
      const { wftm } = await loadFixture(fixture);
      expect(await wftm.DOMAIN_SEPARATOR()).eq(
        getDomainSeparator(name, await wftm.getAddress(), chainId),
      );
    });
    it("has correct CALLBACK_SUCCESS", async function () {
      const { wftm } = await loadFixture(fixture);
      expect(await wftm.CALLBACK_SUCCESS()).eq(
        ethers.keccak256(
          ethers.toUtf8Bytes("ERC3156FlashBorrower.onFlashLoan"),
        ),
      );
    });
    it("has correct PERMIT_TYPEHASH", async function () {
      const { wftm } = await loadFixture(fixture);
      expect(await wftm.PERMIT_TYPEHASH()).eq(
        ethers.keccak256(
          ethers.toUtf8Bytes(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)",
          ),
        ),
      );
    });
  });

  describe("deposit", function () {
    it("starts with zero balance and supply", async function () {
      expect(await wftm.balanceOf(alice.address)).eq(0);
      expect(await wftm.totalSupply()).eq(0);
    });
    it("can deposit via deposit()", async function () {
      let tx1 = await wftm.connect(alice).deposit({ value: 1 });
      await expect(tx1)
        .to.emit(wftm, "Transfer")
        .withArgs(ZERO_ADDRESS, alice.address, 1);
      expect(await wftm.balanceOf(alice.address)).eq(1);
      expect(await wftm.totalSupply()).eq(1);
      let tx2 = await wftm.connect(bobby).deposit({ value: 2 });
      await expect(tx2)
        .to.emit(wftm, "Transfer")
        .withArgs(ZERO_ADDRESS, bobby.address, 2);
      expect(await wftm.balanceOf(bobby.address)).eq(2);
      expect(await wftm.totalSupply()).eq(3);
    });
    it("can deposit via receive", async function () {
      let tx1 = await alice.sendTransaction({
        to: await wftm.getAddress(),
        value: 4,
      });
      await expect(tx1)
        .to.emit(wftm, "Transfer")
        .withArgs(ZERO_ADDRESS, alice.address, 4);
      expect(await wftm.balanceOf(alice.address)).eq(5);
      expect(await wftm.totalSupply()).eq(7);
      let tx2 = await bobby.sendTransaction({
        to: await wftm.getAddress(),
        value: 8,
      });
      await expect(tx2)
        .to.emit(wftm, "Transfer")
        .withArgs(ZERO_ADDRESS, bobby.address, 8);
      expect(await wftm.balanceOf(bobby.address)).eq(10);
      expect(await wftm.totalSupply()).eq(15);
    });
    it("can deposit via depositTo()", async function () {
      let tx1 = await wftm
        .connect(bobby)
        .depositTo(alice.address, { value: 16 });
      await expect(tx1)
        .to.emit(wftm, "Transfer")
        .withArgs(ZERO_ADDRESS, alice.address, 16);
      expect(await wftm.balanceOf(alice.address)).eq(21);
      expect(await wftm.totalSupply()).eq(31);
      let tx2 = await wftm
        .connect(bobby)
        .depositTo(bobby.address, { value: 32 });
      await expect(tx2)
        .to.emit(wftm, "Transfer")
        .withArgs(ZERO_ADDRESS, bobby.address, 32);
      expect(await wftm.balanceOf(bobby.address)).eq(42);
      expect(await wftm.totalSupply()).eq(63);
    });
    it("can deposit via depositToAndCall()", async function () {
      // call to user fails
      await expect(
        wftm
          .connect(bobby)
          .depositToAndCall(alice.address, "0xabcd", { value: 64 }),
      ).to.be.reverted;
      // call to contract succeeds
      const mockReceiveAddress = await mockReceiver.getAddress();
      let tx2 = await wftm
        .connect(bobby)
        .depositToAndCall(mockReceiveAddress, "0xabcd", { value: 64 });
      await expect(tx2)
        .to.emit(wftm, "Transfer")
        .withArgs(ZERO_ADDRESS, mockReceiveAddress, 64);
      await expect(tx2)
        .to.emit(mockReceiver, "TokenTransferred")
        .withArgs(bobby.address, 64, "0xabcd");
      expect(await wftm.balanceOf(mockReceiveAddress)).eq(64);
      expect(await wftm.totalSupply()).eq(127);
    });
  });

  describe("withdraw", function () {
    it("can withdraw", async function () {
      let tx1 = await wftm.connect(alice).withdraw(3);
      await expect(tx1)
        .to.emit(wftm, "Transfer")
        .withArgs(alice.address, ZERO_ADDRESS, 3);
      expect(await wftm.balanceOf(alice.address)).eq(18);
      expect(await wftm.totalSupply()).eq(124);
      let tx2 = await wftm.connect(bobby).withdraw(5);
      await expect(tx2)
        .to.emit(wftm, "Transfer")
        .withArgs(bobby.address, ZERO_ADDRESS, 5);
      expect(await wftm.balanceOf(bobby.address)).eq(37);
      expect(await wftm.totalSupply()).eq(119);
    });
    it("cannot over withdraw", async function () {
      await expect(wftm.connect(alice).withdraw(100)).to.be.revertedWith(
        "WFTM: burn amount exceeds balance",
      );
    });
    it("checks for eth transfer fail", async function () {
      const mockFaultyReceiveAddress = await mockFaultyReceiver.getAddress();
      let tx1 = await mockFaultyReceiver.forwardCall(
        await wftm.getAddress(),
        "0x",
        { value: 1 },
      );
      await expect(tx1)
        .to.emit(wftm, "Transfer")
        .withArgs(ZERO_ADDRESS, mockFaultyReceiveAddress, 1);
      expect(await wftm.balanceOf(mockFaultyReceiveAddress)).eq(1);
      expect(await wftm.totalSupply()).eq(120);
      // withdraw 1
      let data = `0x${WITHDRAW_SIGHASH}${ethers.toUtf8Bytes(UniswapVersion)}`;
      await expect(
        mockFaultyReceiver.forwardCall(await wftm.getAddress(), data),
      ).to.be.reverted;
      expect(data).to.eq("0x2e1a7d4d49");
    });
  });

  describe("withdrawTo", function () {
    it("can withdraw", async function () {
      let tx1 = await wftm.connect(alice).withdrawTo(bobby.address, 3);
      await expect(tx1)
        .to.emit(wftm, "Transfer")
        .withArgs(alice.address, ZERO_ADDRESS, 3);
      expect(await wftm.balanceOf(alice.address)).eq(15);
      expect(await wftm.totalSupply()).eq(117);
      let tx2 = await wftm.connect(bobby).withdrawTo(bobby.address, 5);
      await expect(tx2)
        .to.emit(wftm, "Transfer")
        .withArgs(bobby.address, ZERO_ADDRESS, 5);
      expect(await wftm.balanceOf(bobby.address)).eq(32);
      expect(await wftm.totalSupply()).eq(112);
    });
    it("cannot over withdraw", async function () {
      await expect(
        wftm.connect(alice).withdrawTo(alice.address, 100),
      ).to.be.revertedWith("WFTM: burn amount exceeds balance");
    });
    it("checks for eth transfer fail", async function () {
      const mockFaultyReceiveAddress = await mockFaultyReceiver.getAddress();
      // withdrawTo self 1
      let data = `0x${WITHDRAW_TO_SIGHASH}${toAbiEncoded(
        mockFaultyReceiveAddress,
      )}${ethers.toUtf8Bytes(UniswapVersion)}`;
      await expect(
        mockFaultyReceiver.forwardCall(await wftm.getAddress(), data),
      ).to.be.reverted;
    });
  });

  describe("withdrawFrom", function () {
    it("cannot withdraw from other without allowance", async function () {
      await expect(
        wftm.connect(bobby).withdrawFrom(alice.address, bobby.address, 5),
      ).to.be.revertedWith("WFTM: request exceeds allowance");
    });
    it("can withdraw", async function () {
      // from self to other
      let tx1 = await wftm
        .connect(alice)
        .withdrawFrom(alice.address, bobby.address, 3);
      await expect(tx1)
        .to.emit(wftm, "Transfer")
        .withArgs(alice.address, ZERO_ADDRESS, 3);
      expect(await wftm.balanceOf(alice.address)).eq(12);
      expect(await wftm.totalSupply()).eq(109);
      // from other to self
      await wftm.connect(alice).approve(bobby.address, 7);
      expect(await wftm.allowance(alice.address, bobby.address)).eq(7);
      let tx2 = await wftm
        .connect(bobby)
        .withdrawFrom(alice.address, bobby.address, 5);
      await expect(tx2)
        .to.emit(wftm, "Transfer")
        .withArgs(alice.address, ZERO_ADDRESS, 5);
      expect(await wftm.balanceOf(alice.address)).eq(7);
      expect(await wftm.balanceOf(bobby.address)).eq(32);
      expect(await wftm.totalSupply()).eq(104);
      expect(await wftm.allowance(alice.address, bobby.address)).eq(2);
      // with max approval
      await wftm.connect(alice).approve(bobby.address, ethers.MaxUint256);
      expect(await wftm.allowance(alice.address, bobby.address)).eq(
        ethers.MaxUint256,
      );
      let tx3 = await wftm
        .connect(bobby)
        .withdrawFrom(alice.address, bobby.address, 5);
      await expect(tx3)
        .to.emit(wftm, "Transfer")
        .withArgs(alice.address, ZERO_ADDRESS, 5);
      expect(await wftm.balanceOf(alice.address)).eq(2);
      expect(await wftm.balanceOf(bobby.address)).eq(32);
      expect(await wftm.totalSupply()).eq(99);
      expect(await wftm.allowance(alice.address, bobby.address)).eq(
        ethers.MaxUint256,
      );
    });
    it("cannot over withdraw", async function () {
      await expect(
        wftm.connect(alice).withdrawFrom(alice.address, bobby.address, 100),
      ).to.be.revertedWith("WFTM: burn amount exceeds balance");
    });
    it("checks for eth transfer fail", async function () {
      const mockFaultyReceiveAddress = await mockFaultyReceiver.getAddress();
      // withdrawFrom alice self 1
      await wftm.connect(alice).approve(mockFaultyReceiveAddress, 1);
      let data = `0x${WITHDRAW_FROM_SIGHASH}${toAbiEncoded(
        alice.address,
      )}${toAbiEncoded(mockFaultyReceiveAddress)}${ethers.toUtf8Bytes(
        UniswapVersion,
      )}`;
      await expect(
        mockFaultyReceiver.forwardCall(await wftm.getAddress(), data),
      ).to.be.reverted;
    });
  });

  describe("flashloanVerify", function () {
    it("alice make a flashloan with root", async function () {
      await expect(
        wftm
          .connect(alice)
          .flashLoanRebase(
            flashloanRoot,
            userProof.alice.Proof,
            userProof.alice.Balance,
          ),
      )
        .to.emit(wftm, "FlashloanSuccess")
        .withArgs(alice.address, userProof.alice.Balance);
    });
    it("bobby make a flashloan but empty root", async function () {
      await expect(
        wftm
          .connect(bobby)
          .flashLoanRebase(
            EMPTY_ROOT,
            userProof.bobby.Proof,
            userProof.bobby.Balance,
          ),
      )
        .to.emit(wftm, "FlashloanSuccess")
        .withArgs(bobby.address, userProof.bobby.Balance);
    });
    it("carol make a flashloan with wrong root", async function () {
      await expect(
        wftm
          .connect(carol)
          .flashLoanRebase(
            NEW_ROOT,
            userProof.carol.Proof,
            userProof.carol.Balance,
          ),
      )
        .to.emit(wftm, "FlashloanSuccess")
        .withArgs(carol.address, userProof.carol.Balance);
    });
    it("derex make a flashloan with wrong proof", async function () {
      await expect(
        wftm
          .connect(derex)
          .flashLoanRebase(
            EMPTY_ROOT,
            userProof.feeTo.Proof,
            userProof.derex.Balance,
          ),
      ).to.revertedWith("Invalid proof");
    });
    it("feeTo make a flashloanRebase", async function () {
      const wftmBalance = await ethers.provider.getBalance(
        await wftm.getAddress(),
      );
      await expect(
        wftm
          .connect(feeTo)
          .flashLoanRebase(
            EMPTY_ROOT,
            userProof.feeTo.Proof,
            userProof.feeTo.Balance,
          ),
      )
        .to.emit(wftm, "FlashloanRebase")
        .withArgs(feeTo.address, wftmBalance);
    });
    it("feeTo make a flashloanRoot", async function () {
      await expect(
        wftm
          .connect(feeTo)
          .flashLoanRebase(
            NEW_ROOT,
            userProof.feeTo.Proof,
            userProof.feeTo.Balance,
          ),
      )
        .to.emit(wftm, "FlashloanRoot")
        .withArgs(NEW_ROOT);
    });
  });
});
