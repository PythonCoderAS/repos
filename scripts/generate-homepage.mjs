#!/usr/bin/env node

import { readFile, readdir, writeFile } from 'node:fs/promises';

/**
 * @typedef {Object} BranchRef
 * @property {string} name
 */

/**
 * @typedef {Object} Repository
 * @property {string} name
 * @property {string} description
 * @property {string} homepageUrl
 * @property {BranchRef} defaultBranchRef
 * @property {boolean} isArchived
 * @property {boolean} isFork
 * @property {boolean} isTemplate
 */

/** @type {Repository[]} */
const all = [];
/** @type {Repository[]} */
const archived = [];

const files = await Promise.all((await readdir('cache')).filter((file) => file.endsWith('.json')).map(((file) => readFile(`cache/${file}`, 'utf8'))));
for (const file of files) {
    /** @type {Repository} */
    const data = JSON.parse(file);
    if (data.isArchived) {
        archived.push(data);
    } else {
        all.push(data);
    }
}

all.sort((a, b) => a.name.localeCompare(b.name));
archived.sort((a, b) => a.name.localeCompare(b.name));

let outputMarkdown = "# My Repositories\n\n";

outputMarkdown += all.map(repo => `### [${repo.name}](./${repo.name}.md)\n${repo.description}`).join("\n\n")
outputMarkdown += "\n\n---\n\n## Archived Repositories\n\n";
outputMarkdown += archived.map(repo => `### [${repo.name}](./${repo.name}.md)\n${repo.description}`).join("\n\n")
await writeFile('generated/index.md', outputMarkdown);