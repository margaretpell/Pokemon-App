//
//  PokemonCardView.swift
//  Pokemon
//
//  Created by Peier Chen on 2025-01-30.
//

import SwiftUI
import PokeApi
import PokeApiModels
@MainActor
struct PokemonCardView: View {
    let pokemonId: Int
    @State private var pokemon: Pokemon?
    @State private var isLoading = false
    private let pokeApiClient: PokeApiClientProvider = PokeApiClientProvider()
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let pokemon = pokemon {
                Text(pokemon.name.capitalized)
                    .font(.system(size: 30, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                HStack {
                    if let frontURL = pokemon.sprites.frontDefault {
                        AsyncImage(url: frontURL) { image in
                            image.resizable().scaledToFit().frame(width: 100, height: 100)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    if let backURL = pokemon.sprites.backDefault {
                        AsyncImage(url: backURL) { image in
                            image.resizable().scaledToFit().frame(width: 100, height: 100)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                VStack(alignment: .leading, spacing: 8) {
                    if let stats = pokemon.stats.first(where: { $0.stat.name == "hp" }) {
                        Text("Hit Points: \(stats.baseStat)")
                    }
                    Text("Height: \(pokemon.height)")
                    Text("Order: \(pokemon.order)")
                    Text("Weight: \(pokemon.weight)")
                    Text("Base Experience: \(pokemon.baseExperience ?? 0)")
                }
                .font(.system(size: 18))
                .padding(.horizontal, 16)
            } else if isLoading {
                ProgressView()
            } else {
                Text("Failed to load Pokémon")
            }
        }
        .padding()
        .task {
            await fetchPokemon()
        }
    }
    
    private func fetchPokemon() async {
        guard !isLoading else { return }
        isLoading = true
        do {
            guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(pokemonId)") else {
                isLoading = false
                return
            }
            let request = URLRequest(url: url)
            let (data, response) = try await pokeApiClient.session.data(for: request)
            if let error = try? pokeApiClient.processApiResponse(response: response) {
                throw error
            }
            let fetchedPokemon = try await pokeApiClient.decoder.decode(Pokemon.self, from: data)
            self.pokemon = fetchedPokemon
            self.isLoading = false
        } catch {
            self.isLoading = false
        }
    }
}
