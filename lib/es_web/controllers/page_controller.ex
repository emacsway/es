defmodule EsWeb.PageController do
  use EsWeb, :controller

  alias Es.Accounts

  def index(conn, _params) do
    render conn, "index.html", accounts: Accounts.list_accounts()
  end

  def handle_command(conn, %{ "command" => %{"type" => "create_account", "account_number" => an, "name" => n, "initial_balance" => ib}}) do
    {ib, _} = Float.parse(ib)

    with {:ok, _account} <- Accounts.create_account(%{account_number: an, initial_balance: ib, name: n}) do
    	redirect(conn, to: page_path(conn, :index))
    end
  end

  def handle_command(conn, %{ "command" => %{"type" => "withdrawal", "account_number" => an, "amount" => a, "where" => w}}) do
    {a, _} = Float.parse(a)

    case Accounts.account_by_account_number(an) do
      nil -> nil
      account -> Accounts.withdraw(account, %{amount: a, where: w})
    end

    redirect(conn, to: page_path(conn, :index))
  end

  def handle_command(conn, %{ "command" => %{"type" => "deposit", "account_number" => an, "amount" => a}}) do
    {a, _} = Float.parse(a)

    case Accounts.account_by_account_number(an) do
      nil -> nil
      account -> Accounts.deposit(account, %{amount: a})
    end

    redirect(conn, to: page_path(conn, :index))
  end

  def detail(conn, params) do
    account = Map.get params, "account"
  	accounts = Accounts.list_accounts()

  	selected = 
      accounts
      |> Enum.find(fn
    		%{account_number: ^account} -> true
    		_ -> false
    	end)
    	|> case do
  		  nil -> nil
  		  selected -> %{selected | balance: :erlang.float_to_binary(selected.balance, [decimals: 2])}
  		end

  	withdrawal_stats = Accounts.withdrawal_stats_by_account_number(account)

    render conn, "detail.html",
    	accounts: accounts,
    	selected: selected,
    	number: account,
    	withdrawal_stats: withdrawal_stats
  end
end
