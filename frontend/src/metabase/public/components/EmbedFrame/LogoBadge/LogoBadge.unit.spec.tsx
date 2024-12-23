import { render, screen } from "__support__/ui";

import { LogoBadge } from ".";

describe("LogoBadge", () => {
  it("should render a link with valid utm parameters", () => {
    setup();

    expect(screen.getByRole("link")).toHaveProperty(
      "href",
      "https://www.metabase.com/powered-by-metabase?utm_medium=referral&utm_source=product&utm_campaign=powered_by_metabase&utm_content=embedded_banner_localhost",
    );
  });
});

function setup() {
  render(<LogoBadge dark={false} />);
}
