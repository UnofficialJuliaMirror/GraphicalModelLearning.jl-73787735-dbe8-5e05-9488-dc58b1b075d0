export sample

export GMSampler, Gibbs

using StatsBase

@compat abstract type GMSampler end

type Gibbs <: GMSampler end

function int_to_spin(int_representation::Int, spin_number::Int)
    spin = 2*digits(int_representation, 2, spin_number)-1
    return spin
end

function weigh_proba{T <: Real}(int_representation::Int, adj::Array{T,2}, prior::Array{T,1})
    spin_number  = size(adj,1)
    spins = int_to_spin(int_representation, spin_number)
    return exp(((0.5) * spins' * adj * spins + prior' * spins)[1])
end


bool_to_spin(bool::Int) = 2*bool-1

function weigh_proba{T <: Real}(int_representation::Int, adj::Array{T,2}, prior::Array{T,1}, assignment_tmp::Array{Int,1})
    digits!(assignment_tmp, int_representation, 2)
    bool_to_spin.(assignment_tmp)
    return exp(((0.5) * assignment_tmp' * adj * assignment_tmp + prior' * assignment_tmp)[1])
end


function sample_generation{T <: Real}(samples_per_bin::Integer, adj::Array{T,2}, prior::Array{T,1}, bins::Int)
    @assert bins >= 1

    spin_number   = size(adj,1)
    config_number = 2^spin_number

    assignment_tmp = [0 for i in 1:spin_number] # pre allocate assignment memory
    weights = [weigh_proba(i, adj, prior, assignment_tmp) for i in (0:config_number-1)]

    items = [i for i in 0:(config_number-1)]
    raw_sample = StatsBase.sample(items, StatsBase.Weights(weights), samples_per_bin*bins, ordered=false)
    raw_sample_bins = reshape(raw_sample, bins, samples_per_bin)

    spin_samples = []
    for b in 1:bins
        raw_binning = countmap(raw_sample_bins[b,:])
        spin_sample = [ vcat(raw_binning[i], int_to_spin(i, spin_number)) for i in keys(raw_binning)]
        push!(spin_samples, hcat(spin_sample...)')
    end
    return spin_samples
end

sample{T <: Real}(adjacency_matrix::Array{T,2}, number_sample::Integer) = sample(adjacency_matrix, number_sample, 1, Gibbs())[1]
sample{T <: Real}(adjacency_matrix::Array{T,2}, number_sample::Integer, replicates::Integer) = sample(adjacency_matrix, number_sample, replicates, Gibbs())

function sample{T <: Real}(adjacency_matrix::Array{T,2}, number_sample::Integer, replicates::Integer, sampler::Gibbs)
    prior_vector = transpose(diag(adjacency_matrix))[1,:] #priors, or magnetic fields part

    # generation of samples
    samples = sample_generation(number_sample, adjacency_matrix, prior_vector, replicates)

    return samples
end
