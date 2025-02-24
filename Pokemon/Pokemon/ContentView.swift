import SwiftUI
import PokeApi
import PokeApiAsync
import PokeApiModels
import VSM

enum ContentViewState {
    case initialize(InitializedViewStateModel)
    case loading
    case loaded(LoadedViewStateModel)
    case error(Error)
}

extension ContentViewState {
    struct InitializedViewStateModel {
        func fetchPokemonSequence(pokeApiClient: PokeApiClientProvider) -> StateSequence<ContentViewState> {
            .init(
                { .loading },
                { await fetchPokemon(pokeApiClient: pokeApiClient) }
            )
        }


        func fetchPokemon(pokeApiClient: PokeApiClientProvider) async -> ContentViewState {
            do {
                let page = try await pokeApiClient.getResourcesForPage(of: Pokemon.self, from: 0, limit: 100)
                return .loaded(LoadedViewStateModel(pokemon: page, pokeApiClient: pokeApiClient, currentPage: 1))
            } catch {
                print("Error fetching Pokémon: \(error)")
                return .error(error)
            }
        }
    }

    struct LoadedViewStateModel {
        let pokeApiClient: PokeApiClientProvider
        let currentPage: Int
        let pageSize: Int = 100
        var pokemon: [Pokemon]
        var isLoading: Bool

        init(pokemon: [Pokemon], pokeApiClient: PokeApiClientProvider, currentPage: Int = 1, isLoading: Bool = false) {
            self.pokemon = pokemon
            self.pokeApiClient = pokeApiClient
            self.currentPage = currentPage
            self.isLoading = isLoading
        }

        func fetchNextPage() -> StateSequence<ContentViewState> {
            guard !isLoading else { return .init { .loaded(self) } }


            return .init(
                { .loaded(self.copyWith(isLoading: true)) },
                {
                    await self.loadMorePokemon()
                }
            )
        }

        private func loadMorePokemon() async -> ContentViewState {
            do {
                let newPage = try await pokeApiClient.getResourcesForPage(
                    of: Pokemon.self,
                    from: currentPage * pageSize,
                    limit: pageSize
                )

                let uniquePokemon = self.pokemon + newPage.filter { newPoke in
                    !self.pokemon.contains(where: { $0.id == newPoke.id })
                }


                return .loaded(
                    self.copyWith(
                        pokemon: uniquePokemon,
                        currentPage: currentPage + 1,
                        isLoading: false
                    )
                )
            } catch {
                print("Error fetching Pokémon: \(error)")
                return .error(error)
            }
        }

        private func copyWith(
            pokemon: [Pokemon]? = nil,
            currentPage: Int? = nil,
            isLoading: Bool? = nil
        ) -> LoadedViewStateModel {
            return LoadedViewStateModel(
                pokemon: pokemon ?? self.pokemon,
                pokeApiClient: self.pokeApiClient,
                currentPage: currentPage ?? self.currentPage,
                isLoading: isLoading ?? self.isLoading
            )
        }
    }
}

struct ContentView: View {
    @ViewState var state: ContentViewState = .initialize(.init())
    let pokeApiClient: PokeApiClientProvider = PokeApiClientProvider()

    var body: some View {
        switch state {
        case .initialize(let viewModel):
            Color.clear.onAppear {
                $state.observeAsync {
                    viewModel.fetchPokemonSequence(pokeApiClient: pokeApiClient)
                }
            }
        case .loaded(let viewModel):
            pokemonList(viewModel: viewModel)
        case .error(let error):
            VStack {
                Text(error.localizedDescription)
            }
        case .loading:
            ProgressView().progressViewStyle(.circular)
        }
    }

    @ViewBuilder
    func pokemonList(viewModel: ContentViewState.LoadedViewStateModel) -> some View {
            List {
                Section {
                    ForEach(viewModel.pokemon) { poke in
                        NavigationLink(value: PokeDestination.cardView(poke.id)) {
                            PokemonRowView(pokemon: poke)
                        }
                        .onAppear {
                            if poke.id == viewModel.pokemon.last?.id && !viewModel.isLoading {
                                $state.observeAsync {
                                    viewModel.fetchNextPage()
                                }
                            }
                        }
                    }
                }
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        Text("Loading...")
                        Spacer()
                    }
                }
            }
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PokeDestination.self) {
                switch $0 {
                case .cardView(let id):
                    PokemonCardView(pokemonId: id)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Pokemon")
                        .font(.system(size: 30, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
    }
}

struct PokemonRowView: View {
    let pokemon: Pokemon
    var body: some View {
        HStack {
            AsyncImage(url: pokemon.sprites.frontDefault)
            Text(pokemon.name)
        }
    }
}

enum PokeDestination: Hashable {
    case cardView(Int)
}

#Preview {
    ContentView()
}
