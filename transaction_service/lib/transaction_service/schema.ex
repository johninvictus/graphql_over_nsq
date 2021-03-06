defmodule TransactionService.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias Absinthe.{Resolution}

  alias TransactionService
  alias TransactionService.{ParseContext, TranslateErrors}

  def middleware(middleware, %{identifier: identifier} = field, object) do
    field_name = Atom.to_string(identifier)

    new_middleware_spec = {{__MODULE__, :get_field_key}, {field_name, identifier}}

    Absinthe.Schema.replace_default(middleware, new_middleware_spec, field, object)
  end

  def get_field_key(%Resolution{source: source} = res, {key, fallback_key}) do
    new_value =
      case Map.fetch(source, key) do
        {:ok, value} ->
          value

        :error ->
          Map.get(source, fallback_key)
      end

    %{res | state: :resolved, value: new_value}
  end

  object :field_error do
    description("An user-readable error")

    field(:field, non_null(:string), description: "Error field")

    field(:message, non_null(:string), description: "Error description")
  end

  object :user_transaction do
    description("User transactions")

    field(:id, non_null(:id), description: "Transaction ID")
    field(:user_id, non_null(:string), description: "Transaction email")

    field(:code, non_null(:string), description: "Transaction code")

    field(:items, non_null(list_of(non_null(:transaction_item))), description: "Transaction items")
  end

  object :transaction_item do
    description("Transaction items")

    field(:id, non_null(:id), description: "Item ID")
    field(:product_id, non_null(:id), description: "Product ID")

    field(:price, non_null(:float), description: "Item price")
    field(:quantity, non_null(:float), description: "Item quantity")
  end

  input_object :create_transaction_item do
    description("Create transaction item")

    field(:product_id, non_null(:id), description: "Item product ID")
    field(:quantity, non_null(:float), description: "Item product quantiy")
  end

  query do
    field :user_transactions, non_null(list_of(non_null(:user_transaction))) do
      description("User transaction")

      arg(:user_id, non_null(:id), description: "User Id")

      resolve(fn _, %{user_id: user_id}, _ ->
        {:ok, TransactionService.get_all_user_transactions(user_id)}
      end)
    end
  end

  mutation do
    payload field(:create_transaction) do
      description("Create transaction")
      middleware(ParseContext)

      input do
        field(:items, list_of(:create_transaction_item), description: "Items")
      end

      output do
        field(:transaction, :user_transaction, description: "Newly created transaction")

        field :errors, non_null(list_of(non_null(:field_error))) do
          description("Mutation errors")

          middleware(TranslateErrors)
        end
      end

      resolve(fn _, args, %{context: %{current_user: %{id: user_id}} = context} ->
        case TransactionService.create_transaction(user_id, args) do
          {:ok, transaction} -> %{transaction: transaction, errors: []}
          {:error, changeset} -> %{transaction: nil, errors: changeset}
        end
        |> (&{:ok, &1}).()
      end)
    end
  end
end
