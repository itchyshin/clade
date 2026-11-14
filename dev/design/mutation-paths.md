# Genome and brain mutation paths

Issue #111 asked why `_mutate_weights()` and per-brain `mutate()` methods
both exist. They operate on different representations and reproduction
paths. Keeping them separate preserves current simulation behavior.

## Prey: inherited genome alleles

`genome.jl::meiosis()` calls `_mutate_weights()` on the inherited weight
vector after copying a haploid parent or recombining diploid chromosomes.
The helper adds Gaussian noise with the specs-driven mutation standard
deviation. Prey reproduction builds the offspring brain from the resulting
genome. It does not then call the per-brain mutation method again.

## Predators: direct brain mutation

`modules/tick_predators.jl::_predator_reproduction!()` calls `mutate()` on the
parent's brain. Predator offspring currently retain the parent's genome
object, while receiving the mutated brain. This path therefore has different
inheritance semantics from prey reproduction.

The brain methods also preserve architecture-specific behavior:

- ANN mutation perturbs layer weights and biases.
- BNN mutation perturbs mu and preserves sigma.
- CTRNN mutation handles positive, bounded time constants in log space
  and resets the dynamic state.
- GRN mutation resets gene-expression state in the offspring brain.

These functions are not applied twice along the same offspring path.
Consolidating their Gaussian operations alone could lose architecture
state handling or alter which representation is inherited. A future change
to unify predator and prey inheritance would need its own biological
contract and regression tests.

## Maintenance decision

Retain both paths and close #111 as an explained design distinction.
Changing predator inheritance is outside that issue's duplication question.
The source files above remain authoritative for exact operations.
