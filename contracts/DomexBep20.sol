// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

import "./interface/IBEP20.sol";
import "./utils/Context.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";

/*
 * @title DOMEX Token Contract
 * @author aristatait@gmail.com
 * @notice DOMEX 토큰은 BEP20 표준을 구현하였습니다.
 */
contract DomexBep20 is Context, Ownable, IBEP20 {
  // uint256 자료형에 대해 SafeMath 라이브러리를 적용한다
  using SafeMath for uint256;

  // 잔액을 저장할 스토리지
  mapping(address => uint256) private _balances;
  // 승인 내역을 저장할 스토리지
  mapping(address => mapping(address => uint256)) private _allowances;
  // 총 공급량
  uint256 private _totalSupply;
  // 자릿수
  uint8 private _decimals;
  // 토큰 심볼
  string private _symbol;
  // 토큰 이름
  string private _name;

  // 생성자 - 컨트랙트를 배포할 때 한번만 실행 된다
  constructor() {
    _name = "DOMEX";
    _symbol = "DMX";
    _decimals = 18;
    _totalSupply = 1000000000 * 10 ** 18;
    // 10억개
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @notice 토큰 이름을 반환한다
   */
  function name() override external view returns (string memory) {
    return _name;
  }

  /**
   * @notice 토큰 심볼을 반환한다
   */
  function symbol() override external view returns (string memory) {
    return _symbol;
  }

  /**
   * @notice 토큰 자릿수를 반환한다
   */
  function decimals() override external view returns (uint8) {
    return _decimals;
  }

  /**
   * @notice 토큰 총 공급량을 반환한다
   */
  function totalSupply() override external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @notice 인수로 받은 계정의 토큰 잔액을 반환한다
   */
  function balanceOf(address account) override external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @notice 토큰 소유자를 반환한다
   */
  function getOwner() override external view returns (address) {
    return owner();
  }

  /**
   * @notice 함수 호출자의 토큰을 토큰 수령자에게 입력한 수량 만큼 전송한다
   * @dev
   *  - 토큰 수령자의 주소가 0 이 되면 안된다
   *  - 함수 호출자의 잔액이 보내려는 수량 보다 많아야 한다
   *  - 위의 확인 로직들은 private _transfer 함수에 구현한다
   */
  function transfer(address recipient, uint256 amount) override external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @notice sender 의 토큰을 recipient 에게 압력한 수량 만큼 전송한다
   * @dev
   *  - 보내는 사람의 주소와 받는 사람의 주소가 0이 되면 안된다
   *  - 보내는 사람의 잔액이 보내는 금액 보다 작으면 안된다
   *  - 함수 호출자는 보내는 사람의 토큰에 대해서 amount 이상의 허가가 있어야 한다
   *  - Approve 이벤트도 호출해야 한다
   */
  function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @notice sender 의 토큰을 recipient 에게 amount 만큼 전송한다
   * @dev 이 함수는 transfer 함수의 실제 구현부 이다. trasferFrom 의 구현부와 중복되는 로직을 메소드화 시켰다
   *  - sender 의 주소가 0 이 되면 안된다
   *  - recipient 의 주소가 0 이 되면 안된다
   *  - sender 의 잔액이 반드시 보내려는 수량 보다 많아야 한다
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    // sender 의 주소가 0 인지 확인하고, 0 이라면 에러를 반환한다
    require(sender != address(0), "The address of sender must not be 0.");
    // recipient 의 주소가 0 인지 확인하고, 0 이라면 에러를 반환한다
    require(recipient != address(0), "The address of recipient must not be 0.");

    // sender 의 잔액을 amount 만큼 차감한다.
    // 동시에 sender 의 잔액이 amount 보다 작으면 에러를 반환한다
    // 에러는 SafeMath 에 require 로 구현되어 있다
    _balances[sender] = _balances[sender].sub(amount, "The balance of sender must be greater than the amount to be sent");

    // recipient 의 잔액을 전송액 만큼 가산한다.
    _balances[recipient] = _balances[recipient].add(amount);
    // 전송 이벤트를 호출한다
    emit Transfer(sender, recipient, amount);
  }

  /**
   * @notice 함수 호출자의 토큰을 토큰 수령자에게 입력한 금액에서 수수료를 차감한 만큼 전송한다
   * @dev
   *  - 토큰 수령자의 주소가 0 이 되면 안된다
   *  - 함수 호출자의 잔액이 보내려는 수량 보다 많아야 한다
   *  - 위의 확인 로직들은 private _transfer 함수에 구현한다
   */
  function transferWithFee(address recipient, uint256 amount, uint256 fee) external returns (bool) {
    _transferWithFee(_msgSender(), recipient, amount, fee);
    return true;
  }

  /**
   * @notice sender 의 토큰을 recipient 에게 압력한 금액에서 수수료를 차감한 만큼 전송한다
   * @dev
   *  - 보내는 사람의 주소와 받는 사람의 주소가 0이 되면 안된다
   *  - 보내는 사람의 잔액이 보내는 금액 보다 작으면 안된다
   *  - 함수 호출자는 보내는 사람의 토큰에 대해서 amount 이상의 허가가 있어야 한다
   *  - Approve 이벤트도 호출해야 한다
   */
  function transferFromWithFee(address sender, address recipient, uint256 amount, uint256 fee) external returns (bool) {
    _transferWithFee(sender, recipient, amount, fee);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @notice sender 의 토큰을 recipient 에게 amount 에서 수수료를 차감한 만큼 전송한다.
   * @dev
   *  - sender 의 주소가 0 이 되면 안된다
   *  - recipient 의 주소가 0 이 되면 안된다
   *  - sender 의 잔액이 반드시 보내려는 수량 보다 많아야 한다
   */
  function _transferWithFee(address sender, address recipient, uint256 amount, uint256 fee) internal {
    // sender 의 주소가 0 인지 확인하고, 0 이라면 에러를 반환한다
    require(sender != address(0), "The address of sender must not be 0.");
    // recipient 의 주소가 0 인지 확인하고, 0 이라면 에러를 반환한다
    require(recipient != address(0), "The address of recipient must not be 0.");


    // 수수료 차감 전송액을 구한다
    uint transferAmount = amount.sub(fee);

    // sender 의 잔액을 amount 만큼 차감한다.
    // 동시에 sender 의 잔액이 amount 보다 작으면 에러를 반환한다
    // 에러는 SafeMath 에 require 로 구현되어 있다
    _balances[sender] = _balances[sender].sub(amount, "The balance of sender must be greater than the amount to be sent");

    // recipient 의 잔액을 수수료 차감 전송액 만큼 가산한다.
    _balances[recipient] = _balances[recipient].add(transferAmount);
    // 전송 이벤트를 호출한다
    emit Transfer(sender, recipient, transferAmount);

    // owner 의 잔액을 전송 수수료 만큼 가산한다
    _balances[owner()] = _balances[owner()].add(fee);
    // 전송 이벤트를 호출한다
    emit Transfer(sender, owner(), fee);
  }

  /**
   * @dev spender 에게 amount 만큼의 토큰을 인출할 권리를 부여한다.
   *
   *  - `spender` 의 주소는 0 이 되면 안된다
   */
  function approve(address spender, uint256 amount) override external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev 토큰 소유자인 owner 가  spender 에게 amount 만큼의 토큰을 인출할 권리를 부여한다
   *
   *  - `owner` 의 주소는 0 이 되면 안된다
   *  - `spender` 의 주소는 0 이 되면 안된다
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev owner 가 spender 에게 인출을 허락한 토큰의 개수를 반환한다
   */
  function allowance(address owner, address spender) override external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev 함수 호출자가 spender 에게 addedValue 만큼의 allowance 를 추가한다
   *  - Approval 이벤트를 호출해야만 한다
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev 함수 호출자가 spender 에게 subtractedValue 만큼의 allowance 를 차감한다
   *  - `spender` 주소는 0 이 되면 안된다
   *  - `spender` 가 이미 가진 allowance 가 subtractedValue 보다 작으면 안된다
   *  - Approval 이벤트를 호출해야만 한다
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  /**
   * @dev 함수 호출자의 토큰을 amount 만큼 소각 한다
   */
  function burn(uint256 amount) public returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  /**
   * @dev 함수 호출자의 토큰을 amount 만큼 소각 한다
   */
  function burnFrom(address account, uint256 amount) public returns (bool) {
    _burnFrom(account, amount);
    return true;
  }

  /**
   * @dev account 주소에서 amount 만큼 토큰을 소각한다
   * - Transfer 이벤트를 호출해야한다. 이때 to 인자로 0 을 넣는다
   *
   * - `account` 주소는 0 이 되면 안된다
   * - `account` 주소가 amount 이상의 토큰을 가지고 있어야 한다
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev account 주소에서 amount 만큼 토큰을 소각한다
   * - 이 함수는 account 주소의 owner 가 아닌 제 3자가 호출한다
   * - 그래서 approve 가 필요하다
   * - amount 만큼 allowance 를 차감해야 한다
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}