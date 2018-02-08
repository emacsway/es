defmodule Es.AccountsTest do
  use Es.DataCase

  import Commanded.Assertions.EventAssertions

  alias Es.Accounts
  alias Es.Accounts.Projections.Account
  alias Es.Accounts.Events.{
    AccountCreated,
    MoneyDeposited,
    MoneyWithdrawn,
    WithdrawalStatCreated,
    AtmCountIncreased,
    BranchCountIncreased,
    AccountStatementCreated,
    AccountStatementTransactionAdded
  }


  describe "create account" do
    @tag :integration
    test "should succeed" do
      params = build(:account)
      assert {:ok, %Account{} = account} = Accounts.create_account(params)

      assert_receive_event AccountCreated, fn event ->
        assert event.account_number == account.account_number
        assert event.name == account.name
        assert event.initial_balance == account.balance
        assert event.account_uuid == account.uuid
      end

      assert account.account_number == params.account_number
      assert account.name == params.name
      assert account.balance == params.initial_balance
    end

    @tag :integration
    test "should fail when registering identical account numbers time and return error" do
      1..2
      |> Enum.map(fn _ -> Task.async(fn -> Accounts.create_account(build(:account)) end)  end)
      |> Enum.map(&Task.await/1)
    end
  end

  describe "deposit money into account" do
    @tag :integration
    test "should succeed" do
      params = build(:account)
      assert {:ok, %Account{} = account} = Accounts.create_account(params)
      initial_balance = account.balance

      assert {:ok, account} = Accounts.deposit(account, %{amount: 1000})

      assert_receive_event MoneyDeposited, fn event ->
        assert event.account_number == account.account_number
        assert event.amount == 1000
        assert event.account_uuid == account.uuid
      end

      assert account.balance == initial_balance + 1000
    end
  end

  describe "withdraw money from account" do
    @tag :integration
    test "should succeed" do
      params = build(:account, initial_balance: 1000.0)
      assert {:ok, %Account{} = account} = Accounts.create_account(params)
      initial_balance = account.balance

      assert {:ok, account} = Accounts.withdraw(account, %{amount: 500, where: "branch"})

      assert_receive_event MoneyWithdrawn, fn event ->
        assert event.account_number == account.account_number
        assert event.amount == 500
        assert event.where == "branch"
        assert event.account_uuid == account.uuid
      end

      assert account.balance == initial_balance - 500
    end
  end
end
