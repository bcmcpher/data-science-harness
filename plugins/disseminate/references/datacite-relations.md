# DataCite `RelatedIdentifier` relation types (reference)

`link-outputs` records how a project's products relate, using DataCite Metadata Schema
`relationType` values. Each relation has an **inverse**: when you link two *internal* products
(both in this ledger), record the relation on the source and its inverse on the target so the graph
stays consistent and navigable in either direction.

## Common relation types and their inverses

| relationType | Inverse | Typical use in a research compendium |
|---|---|---|
| `IsSourceOf` | `IsDerivedFrom` | dataset `IsSourceOf` the paper's results |
| `IsDerivedFrom` | `IsSourceOf` | agent-bundle `IsDerivedFrom` the analysis code |
| `IsSupplementTo` | `IsSupplementedBy` | dataset `IsSupplementTo` the paper |
| `IsSupplementedBy` | `IsSupplementTo` | paper `IsSupplementedBy` its dataset |
| `IsDocumentedBy` | `Documents` | dataset `IsDocumentedBy` the article/preprint |
| `Documents` | `IsDocumentedBy` | executable article `Documents` the dataset |
| `IsVariantFormOf` | `IsOriginalFormOf` | Lab-in-a-Box mirror `IsVariantFormOf` the dataset |
| `IsVersionOf` | `HasVersion` | a tagged release `IsVersionOf` the concept record |
| `References` | `IsReferencedBy` | paper `References` an external dataset/DOI |
| `IsPartOf` | `HasPart` | one figure's data `IsPartOf` the paper product |

## Recording conventions
- **Target** is either another product `id` in this ledger (internal link) or an external
  resolvable identifier (a DOI/URL). Prefer internal `id` links for products in this project — they
  resolve to the product's own DOI once it is released.
- For **internal** links, record the **inverse** on the target product too.
- For **external** links (to a DOI/URL not in this ledger), record only the forward relation.
- Do not invent DOIs — reference a product `id` (which may not be released yet) or a real,
  resolvable identifier. An unreleased internal target is fine; note it so it gets a DOI at release.
- Relations are the canonical record in `products[].relations`; the dataset product's external
  relations may additionally be mirrored into `dataset_description.json`.

Full vocabulary: DataCite Metadata Schema, `relatedIdentifier`/`relationType`.
