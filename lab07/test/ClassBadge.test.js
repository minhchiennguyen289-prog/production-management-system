const { expect } = require('chai');
const { ethers } = require('hardhat');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
async function fixture() {
  const [owner, alice, other] = await ethers.getSigners();
  const badge = await ethers.deployContract('ClassBadge', [owner.address]);
  await badge.waitForDeployment();
  return { badge, owner, alice, other };
}
function decode(uri) {
  expect(uri).to.match(/^data:application\/json;base64,/);
  return JSON.parse(Buffer.from(uri.split(',')[1], 'base64').toString('utf8'));
}
describe('ClassBadge / ERC-721', function () {
  it('has correct collection metadata and owner', async function () {
    const { badge, owner } = await loadFixture(fixture);
    expect(await badge.name()).to.equal('ClassBadge');
    expect(await badge.symbol()).to.equal('CBADGE');
    expect(await badge.owner()).to.equal(owner.address);
  });
  it('owner mints id 0, returns the id and emits Transfer', async function () {
    const { badge, alice } = await loadFixture(fixture);
    expect(await badge.mint.staticCall(alice.address, 'Student A')).to.equal(0n);
    await expect(badge.mint(alice.address, 'Student A'))
      .to.emit(badge, 'Transfer').withArgs(ethers.ZeroAddress, alice.address, 0n);
    expect(await badge.ownerOf(0)).to.equal(alice.address);
    expect(await badge.balanceOf(alice.address)).to.equal(1n);
  });
  it('rejects mint by non-owner', async function () {
    const { badge, alice } = await loadFixture(fixture);
    await expect(badge.connect(alice).mint(alice.address, 'Student A'))
      .to.be.revertedWithCustomError(badge, 'OwnableUnauthorizedAccount').withArgs(alice.address);
  });
  it('rejects an empty name', async function () {
    const { badge, alice } = await loadFixture(fixture);
    await expect(badge.mint(alice.address, ''))
      .to.be.revertedWithCustomError(badge, 'EmptyName');
  });
  it('rejects tokenURI for an unminted ID', async function () {
    const { badge } = await loadFixture(fixture);
    await expect(badge.tokenURI(0))
      .to.be.revertedWithCustomError(badge, 'ERC721NonexistentToken').withArgs(0n);
  });
  it('decodes JSON, Student trait and nested base64 SVG', async function () {
    const { badge, alice } = await loadFixture(fixture);
    await badge.mint(alice.address, 'Nguyễn Văn An');
    const meta = decode(await badge.tokenURI(0));
    expect(meta.name).to.equal('ClassBadge #0');
    expect(meta.description).to.equal('Blockchain Lab 07 student badge with on-chain metadata.');
    expect(meta.attributes).to.deep.equal([{ trait_type: 'Student', value: 'Nguyễn Văn An' }]);
    expect(meta.image).to.match(/^data:image\/svg\+xml;base64,/);
    const svg = Buffer.from(meta.image.split(',')[1], 'base64').toString('utf8');
    expect(svg).to.include('<svg xmlns="http://www.w3.org/2000/svg"');
    expect(svg).to.include('ClassBadge #0');
    expect(svg).to.match(/<\/svg>$/);
  });
  it('preserves Unicode, quotes, backslashes and control characters in JSON', async function () {
    const { badge, alice } = await loadFixture(fixture);
    const name = 'Đỗ "An" \\ nhóm\nA\tB\rC\u0001 <script>';
    await badge.mint(alice.address, name);
    const meta = decode(await badge.tokenURI(0));
    expect(meta.attributes.find(a => a.trait_type === 'Student').value).to.equal(name);
    expect(Buffer.from(meta.image.split(',')[1], 'base64').toString('utf8')).not.to.include('<script>');
  });
  it('increments IDs and keeps independent student names', async function () {
    const { badge, alice, other } = await loadFixture(fixture);
    await badge.mint(alice.address, 'First');
    expect(await badge.mint.staticCall(other.address, 'Second')).to.equal(1n);
    await badge.mint(other.address, 'Second');
    expect(await badge.ownerOf(1)).to.equal(other.address);
    expect(decode(await badge.tokenURI(0)).attributes[0].value).to.equal('First');
    expect(decode(await badge.tokenURI(1)).attributes[0].value).to.equal('Second');
  });
  it('safeMint accepts a receiver implementing the required selector', async function () {
    const { badge } = await loadFixture(fixture);
    const receiver = await ethers.deployContract('AcceptingReceiver');
    await badge.mint(await receiver.getAddress(), 'Student');
    expect(await badge.ownerOf(0)).to.equal(await receiver.getAddress());
  });
  it('safeMint rejects a non-receiver and rolls back the token counter', async function () {
    const { badge, alice } = await loadFixture(fixture);
    const receiver = await ethers.deployContract('NonReceiver');
    await expect(badge.mint(await receiver.getAddress(), 'Student'))
      .to.be.revertedWithCustomError(badge, 'ERC721InvalidReceiver').withArgs(await receiver.getAddress());
    expect(await badge.mint.staticCall(alice.address, 'Student')).to.equal(0n);
  });
  it('safeMint rejects a receiver returning the wrong selector', async function () {
    const { badge } = await loadFixture(fixture);
    const receiver = await ethers.deployContract('WrongReceiver');
    await expect(badge.mint(await receiver.getAddress(), 'Student'))
      .to.be.revertedWithCustomError(badge, 'ERC721InvalidReceiver').withArgs(await receiver.getAddress());
  });
  it('safeTransferFrom rejects non-receivers and preserves ownership', async function () {
    const { badge, alice } = await loadFixture(fixture);
    const receiver = await ethers.deployContract('NonReceiver');
    await badge.mint(alice.address, 'Student');
    await expect(badge.connect(alice)['safeTransferFrom(address,address,uint256)'](
      alice.address, await receiver.getAddress(), 0))
      .to.be.revertedWithCustomError(badge, 'ERC721InvalidReceiver');
    expect(await badge.ownerOf(0)).to.equal(alice.address);
  });
  it('owner may transfer a badge to an EOA without changing its metadata', async function () {
    const { badge, alice, other } = await loadFixture(fixture);
    await badge.mint(alice.address, 'Student');
    const before = await badge.tokenURI(0);
    await badge.connect(alice)['safeTransferFrom(address,address,uint256)'](alice.address, other.address, 0);
    expect(await badge.ownerOf(0)).to.equal(other.address);
    expect(await badge.tokenURI(0)).to.equal(before);
  });
});
