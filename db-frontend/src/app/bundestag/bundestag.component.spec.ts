import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BundestagComponent } from './bundestag.component';

describe('BundestagComponent', () => {
  let component: BundestagComponent;
  let fixture: ComponentFixture<BundestagComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ BundestagComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(BundestagComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
